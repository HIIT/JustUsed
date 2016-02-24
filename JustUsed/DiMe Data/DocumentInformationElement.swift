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

/// Represents dime' Document **and ScientificDocument** classes
class DocumentInformationElement: DiMeBase {
    
    var isPdf: Bool { get {
        return theDictionary["mimeType"] as! String == "application/pdf"
    }  }
    
    let kMaxPlainTextLength: Int = 1000
    
    /// Creates a document from a Safari history element
    init(fromSafariHist histItem: BrowserHistItem) {
        super.init()
        
        theDictionary["appId"] = "JustUsed_\(histItem.url.sha1())"
        theDictionary["mimeType"] = "text/html"
        theDictionary["uri"] = histItem.url
        if let title = histItem.title {
            theDictionary["title"] = title
        }
        
        // attempt to fetch plain text from url
        if let url = NSURL(string: histItem.url), urlData = NSData(contentsOfURL: url), atString = NSAttributedString(HTML: urlData, documentAttributes: nil) {
            theDictionary["plainTextContent"] = atString.string
            theDictionary["contentHash"] = atString.string.sha1()
        }
        
        // set dime-required fields
        theDictionary["@type"] = "Document"
        theDictionary["type"] = "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo/#HtmlDocument"
        theDictionary["isStoredAs"] = "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo/#RemoteDataObject"
    }
    
    /// Creates a document from a Spotlight history element
    init(fromRecentDoc histItem: RecentDocItem) {
        super.init()
        var id: String
        
        // check if the histItem contains plain text, if so use for hash and set id
        let mt: NSString = histItem.mime
        if mt.substringToIndex(4) == "text" {
            do {
                let plainText: NSString = try String(contentsOfFile: histItem.path)
                let plainTextString: String = plainText as String
                id = plainTextString.sha1()
                theDictionary["plainTextContent"] = plainTextString
            } catch (let exception) {
                id = histItem.path.sha1()
                AppSingleton.log.error("Error while fetching plain text from \(histItem.path): \(exception)")
            }
        } else if mt == "application/pdf" {
            // attempt to fetch plain text from pdf
            let docUrl = NSURL(fileURLWithPath: histItem.path)
            if let pdfDoc = PDFDocument(URL: docUrl), plainString = pdfDoc.getText() {
                id = plainString.sha1()
                theDictionary["contentHash"] = plainString.sha1()
                theDictionary["plainTextContent"] = plainString
            } else {
                id = histItem.path.sha1()
            }
        } else {
            id = histItem.path.sha1()
        }
        
        theDictionary["appId"] = "JustUsed_\(id)"
        
        // set everything else apart from plain text and id
        theDictionary["mimeType"] = histItem.mime
        theDictionary["uri"] = "file://" + histItem.path
        theDictionary["title"] = NSURL(fileURLWithPath: histItem.path).lastPathComponent!
        
        // set dime-required fields
        theDictionary["@type"] = "Document"
        theDictionary["type"] = "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo/#Document"
        theDictionary["isStoredAs"] = "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo/#LocalFileDataObject"
    }
    
    /// Converts to scientific document by updating dictionary using crossref metadata. Also accepts keywords (from pdf's metadata).
    func convertToSciDoc(fromCrossRef json: JSON, keywords: [String]?) {
        // dime-required
        theDictionary["@type"] = "ScientificDocument"
        theDictionary["type"] = "http://www.hiit.fi/ontologies/dime/#ScientificDocument"
        
        if let status = json["status"].string where status == "ok" {
            if let title = json["message"]["title"][0].string {
                theDictionary["title"] = title
            }
            if let keywords = keywords {
                theDictionary["keywords"] = keywords
            }
            if let subj = json["message"]["container-title"][0].string {
                theDictionary["booktitle"] = subj
            }
            if let auths = json["message"]["author"].array {
                var authArray = [[String: AnyObject]]()
                for auth in auths {
                    let authString = auth["given"].stringValue + " " + auth["family"].stringValue
                    if let p = Person(fromString: authString) {
                        authArray.append(p.getDict())
                    }
                }
                theDictionary["authors"] = authArray
            }
            if let doi = json["message"]["DOI"].string {
                theDictionary["doi"] = doi
            }
            if let year = json["message"]["issued"]["date-parts"][0][0].int {
                theDictionary["year"] = year
            }
            if let ps = json["message"]["page"].string, words = ps.words() {
                theDictionary["firstPage"] = Int(words[0])
                if words.count > 1 {
                    theDictionary["lastPage"] = Int(words[1])
                }
            }
            if let publisher = json["message"]["publisher"].string {
                theDictionary["publisher"] = publisher
            }
            if let volume = json["message"]["volume"].string {
                theDictionary["volume"] = Int(volume)
            }
        }
    }
    
}
