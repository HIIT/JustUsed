//
// Copyright (c) 2015 Aalto University
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

import Foundation
import Quartz
import Alamofire

extension PDFDocument {
    
    /// Returns the string corresponding to the block with the largest font on the first page.
    /// Returns nil if no information could be found or if two or more blocks have the same largest size.
    func guessTitle() -> String? {
        let astring = pageAtIndex(0).attributedString()
        
        let fullRange = NSMakeRange(0, astring.length)
        
        var textInfo = [(size: CGFloat, range: NSRange)]()
        
        astring.enumerateAttribute(NSFontAttributeName, inRange: fullRange, options: NSAttributedStringEnumerationOptions()) {
            obj, range, stop in
            if let font = obj as? NSFont {
                textInfo.append(size: font.pointSize, range: range)
            }
        }
        
        textInfo.sortInPlace({$0.size > $1.size})
        
        if textInfo.count >= 2 && textInfo[0].size > textInfo[1].size {
            return (astring.string as NSString).substringWithRange(textInfo[0].range)
        } else {
            return nil
        }
    }
    
    /// Returns all keywords in an array, useful for DiMe.
    /// Keywords can be separated by ";" or ","
    func getKeywordsAsArray() -> [String]? {
        guard let keyws = getKeywords() else {
            return nil
        }
        
        var retVal: [String]?
        if keyws.containsChar(";") {
            retVal = keyws.split(";")
        } else if keyws.containsChar(",") {
            retVal = keyws.split(",")
        } else {
            retVal = [keyws]
        }
        if let retVal = retVal {
            return retVal
        } else {
            return nil
        }
    }
    
    func getKeywords() -> String? {
        let docAttrib = documentAttributes()
        if let keywords: AnyObject = docAttrib[PDFDocumentKeywordsAttribute] {
            // some times keywords are in an array
            // other times keywords are all contained in the first element of the array as a string
            // other times they are a string
            if let keywarray = keywords as? [AnyObject] {
                if keywarray.count == 1 {
                    return (keywarray[0] as? String)
                } else {
                    var outStr = ""
                    outStr += keywarray[0] as? String ?? ""
                    for nkw in keywarray {
                        outStr += "; "
                        outStr +=  nkw as? String ?? ""
                    }
                    if outStr == "" {
                        return nil
                    } else {
                        return outStr
                    }
                }
            } else {
                return keywords as? String
            }
        } else {
            return nil
        }
    }
    
    /// Attempts to retrieve metadata for the given pdf.
    /// Returns nil if it couln't be found
    /// - Attention: Blocks while waiting for an answer from crossref, don't use on main thread.
    func getMetadata() -> JSON? {
        // Try to find doi
        var _doi: String? = nil
        
        guard let pageString = self.pageAtIndex(0).string() else {
            return nil
        }
        let doiSearches = ["doi ", "doi:"]
        for doiS in doiSearches {
            let _range = pageString.rangeOfString(doiS, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)
            
            if let r = _range, last = r.last {
                let s = pageString.substringFromIndex(last.advancedBy(1)).trimmed()
                if let doiChunk = s.firstChunk() where doiChunk.characters.count >= 5 {
                    _doi = doiChunk
                    break
                }
            }
        }
        
        // If doi was found, use the crossref api to auto-set metadata
        guard let doi = _doi else {
            return nil
        }
        
        var json: JSON?
        let sema = dispatch_semaphore_create(0)
        
        Alamofire.request(.GET, "http://api.crossref.org/works/\(doi)").responseJSON() {
            response in
            if let resp = response.result.value where response.result.isSuccess {
                let _json = JSON(resp)
                if let status = _json["status"].string where status == "ok" {
                    json = _json
                }
            }
            dispatch_semaphore_signal(sema)
        }
        
        
        let waitTime = dispatch_time(DISPATCH_TIME_NOW, Int64(5.0 * Float(NSEC_PER_SEC)))
        if dispatch_semaphore_wait(sema, waitTime) != 0 {
            AppSingleton.log.warning("Crossref request timed out")
        }
        
        return json
        
    }
    
    /// Returns a trimmed plain text of the data contained in the document, nil not preset
    func getText() -> String? {
        
        var trimmedText = string()
        trimmedText = trimmedText.stringByReplacingOccurrencesOfString("\u{fffc}", withString: "")
        trimmedText = trimmedText.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) // get trimmed version of all text
        trimmedText = trimmedText.stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet()) // trim newlines
        trimmedText = trimmedText.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) // trim again
        if trimmedText.characters.count > 5 {  // we assume the document does contain useful text if there are more than 5 characters remaining
            return trimmedText
        } else {
            return nil
        }
    }
    
}
