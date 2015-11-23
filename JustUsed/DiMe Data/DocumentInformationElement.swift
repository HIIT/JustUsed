//
//  InformationElement.swift
//  PeyeDF
//
//  Created by Marco Filetti on 24/08/2015.
//  Copyright (c) 2015 HIIT. All rights reserved.
//

import Foundation
import Quartz

class DocumentInformationElement: DiMeBase {
    
    let kMaxPlainTextLength: Int = 1000
    
    /// Creates a document from a Safari history element
    init(fromSafariHist histItem: SafariHistItem) {
        super.init()
        
        theDictionary["appId"] = histItem.url.sha1()
        theDictionary["mimeType"] = "text/url"
        theDictionary["uri"] = histItem.url
        if let title = histItem.title {
            theDictionary["title"] = title
        }
        
        // attempt to fetch plain text from url
        if let url = NSURL(string: histItem.url), urlData = NSData(contentsOfURL: url), atString = NSAttributedString(HTML: urlData, documentAttributes: nil) {
            theDictionary["plainTextContent"] = atString.string
        }
        
        // set dime-required fields
        theDictionary["@type"] = "Document"
        theDictionary["type"] = "http://www.hiit.fi/ontologies/dime/#Document"
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
                theDictionary["plainTextContent"] = plainString
            } else {
                id = histItem.path.sha1()
            }
        } else {
            id = histItem.path.sha1()
        }
        
        theDictionary["appId"] = id
        
        // set everything else apart from plain text and id
        theDictionary["mimeType"] = histItem.mime
        theDictionary["uri"] = "file://" + histItem.path
        theDictionary["title"] = NSURL(fileURLWithPath: histItem.path).lastPathComponent!
        
        // set dime-required fields
        theDictionary["@type"] = "Document"
        theDictionary["type"] = "http://www.hiit.fi/ontologies/dime/#Document"
    }
    
}
