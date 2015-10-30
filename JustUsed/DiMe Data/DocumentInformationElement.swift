//
//  InformationElement.swift
//  PeyeDF
//
//  Created by Marco Filetti on 24/08/2015.
//  Copyright (c) 2015 HIIT. All rights reserved.
//

import Foundation

class DocumentInformationElement: DiMeBase {
    
    let kMaxPlainTextLength: Int = 1000
    
    /// Creates a document from a Safari history element
    init(fromSafariHist histItem: SafariHistItem) {
        super.init()
        
        theDictionary["id"] = histItem.url.sha1()
        theDictionary["mimeType"] = "text/url"
        theDictionary["uri"] = histItem.url
        if let title = histItem.title {
            theDictionary["title"] = title
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
                var plainText: NSString = try String(contentsOfFile: histItem.path)
                if plainText.length >= kMaxPlainTextLength {
                    plainText = plainText.substringToIndex(kMaxPlainTextLength)
                }
                let plainTextString: String = plainText as String
                id = plainTextString.sha1()
                theDictionary["plainTextContent"] = plainTextString
            } catch (let exception) {
                id = histItem.path.sha1()
                AppSingleton.log.error("Error while fetching plain text from \(histItem.path): \(exception)")
            }
        } else {
            id = histItem.path.sha1()
        }
        
        theDictionary["id"] = id
        
        // set everything else apart from plain text and id
        theDictionary["mimeType"] = histItem.mime
        theDictionary["uri"] = "file://" + histItem.path
        theDictionary["title"] = NSURL(fileURLWithPath: histItem.path).lastPathComponent!
        
        // set dime-required fields
        theDictionary["@type"] = "Document"
        theDictionary["type"] = "http://www.hiit.fi/ontologies/dime/#Document"
    }
    
}
