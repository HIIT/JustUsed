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
    
    var title: String? {
        get {
            return theDictionary["title"] as? String
        }
        set(title) {
            if let t = title {
                theDictionary["title"] = t as AnyObject
            }
        }
    }
    
    let kMaxPlainTextLength: Int = 1000
    
    /// Creates a document from a Safari history element
    init(fromSafariHist histItem: BrowserHistItem) {
        super.init()
        
        theDictionary["appId"] = "JustUsed_\(histItem.url.sha1())" as AnyObject
        theDictionary["mimeType"] = "text/html" as AnyObject
        theDictionary["uri"] = histItem.url as AnyObject
        if let title = histItem.title {
            theDictionary["title"] = title as AnyObject
        }
        
        // attempt to fetch plain text from url
        if let url = URL(string: histItem.url), let urlData = try? Data(contentsOf: url) {
            do {
                let atString = try NSAttributedString(data: urlData, options: [.documentType: NSAttributedString.DocumentType.html,  .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)
                theDictionary["plainTextContent"] = atString.string
                theDictionary["contentHash"] = atString.string.sha1()
            } catch {
                Swift.print("Failed to convert url contents to string: \(error)")
            }
        }
        
        // set dime-required fields
        theDictionary["@type"] = "Document" as AnyObject
        theDictionary["type"] = "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo/#HtmlDocument" as AnyObject
        theDictionary["isStoredAs"] = "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo/#RemoteDataObject" as AnyObject
    }
    
    /// Creates a document from a Spotlight history element
    init(fromRecentDoc histItem: RecentDocItem) {
        super.init()
        var id: String
        
        // check if the histItem contains plain text, if so use for hash and set id
        let mt: NSString = histItem.mime as NSString
        if mt.substring(to: 4) == "text" {
            do {
                let plainText: NSString = try String(contentsOfFile: histItem.path) as NSString
                let plainTextString: String = plainText as String
                id = plainTextString.sha1()
                theDictionary["plainTextContent"] = plainTextString as AnyObject
            } catch (let exception) {
                id = histItem.path.sha1()
                Swift.print("Error while fetching plain text from \(histItem.path): \(exception)")
            }
        } else if mt == "application/pdf" {
            // attempt to fetch plain text from pdf
            let docUrl = URL(fileURLWithPath: histItem.path)
            if let pdfDoc = PDFDocument(url: docUrl), let plainString = pdfDoc.getText() {
                id = plainString.sha1()
                theDictionary["contentHash"] = plainString.sha1() as AnyObject
                theDictionary["plainTextContent"] = plainString as AnyObject
            } else {
                id = histItem.path.sha1()
            }
        } else {
            id = histItem.path.sha1()
        }
        
        theDictionary["appId"] = "JustUsed_\(id)" as AnyObject
        
        // set everything else apart from plain text and id
        theDictionary["mimeType"] = histItem.mime as AnyObject
        theDictionary["uri"] = "file://" + histItem.path as AnyObject
        theDictionary["title"] = URL(fileURLWithPath: histItem.path).lastPathComponent as AnyObject
        
        // set dime-required fields
        theDictionary["@type"] = "Document" as AnyObject
        theDictionary["type"] = "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo/#Document" as AnyObject
        theDictionary["isStoredAs"] = "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo/#LocalFileDataObject" as AnyObject
    }
    
    /// Converts to scientific document by updating dictionary using crossref metadata. Also accepts keywords (from pdf's metadata).
    func convertToSciDoc(fromCrossRef json: JSON, keywords: [String]?) {
        // dime-required
        theDictionary["@type"] = "ScientificDocument" as AnyObject
        theDictionary["type"] = "http://www.hiit.fi/ontologies/dime/#ScientificDocument" as AnyObject
        
        if let status = json["status"].string, status == "ok" {
            if let title = json["message"]["title"][0].string {
                theDictionary["title"] = title as AnyObject
            }
            if let keywords = keywords {
                theDictionary["keywords"] = keywords as AnyObject
            }
            if let subj = json["message"]["container-title"][0].string {
                theDictionary["booktitle"] = subj as AnyObject
            }
            if let auths = json["message"]["author"].array {
                theDictionary["authors"] = auths.compactMap({Person(fromCrossRef: $0)?.getDict()})
            }
            if let doi = json["message"]["DOI"].string {
                theDictionary["doi"] = doi as AnyObject
            }
            if let year = json["message"]["issued"]["date-parts"][0][0].int {
                theDictionary["year"] = year as AnyObject
            }
            if let ps = json["message"]["page"].string, let words = ps.words() {
                theDictionary["firstPage"] = Int(words[0]) as AnyObject
                if words.count > 1 {
                    theDictionary["lastPage"] = Int(words[1]) as AnyObject
                }
            }
            if let publisher = json["message"]["publisher"].string {
                theDictionary["publisher"] = publisher as AnyObject
            }
            if let volume = json["message"]["volume"].string {
                theDictionary["volume"] = Int(volume) as AnyObject
            }
        }
    }
    
}
