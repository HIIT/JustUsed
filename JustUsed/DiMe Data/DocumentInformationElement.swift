//
//  InformationElement.swift
//  PeyeDF
//
//  Created by Marco Filetti on 24/08/2015.
//  Copyright (c) 2015 HIIT. All rights reserved.
//

import Foundation

class DocumentInformationElement: NSObject, DiMeAble, Dictionariable {
    
    let kMaxPlainTextLength: Int = 500
    
    var json: JSON
    var id: String
    
    /// Creates a document from a Safari history element
    ///
    init(fromSafariHist histItem: SafariHistItem) {
        let emptyDict = [String: AnyObject]()
        json = JSON(emptyDict)
        id = histItem.url.sha1()
        
        super.init() // required
        setDiMeDict() // required
        
        json["id"] = JSON(histItem.url.sha1())
        json["mimeType"] = JSON("text/url")
        json["uri"] = JSON(histItem.url)
        if let title = histItem.title {
            json["title"] = JSON(title)
        }
    }
    
    /// Creates a document from a Spotlight history element
    init(fromSpotlightHist histItem: SpotlightHistItem) {
        let emptyDict = [String: AnyObject]()
        json = JSON(emptyDict)
        
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
                json["plainTextContent"] = JSON(plainTextString)
            } catch (let exception) {
                id = histItem.path.sha1()
                AppSingleton.log.error("Error while fetching plain text from \(histItem.path): \(exception)")
            }
        } else {
            id = histItem.path.sha1()
        }
        
        json["id"] = JSON(id)
        
        super.init()
        setDiMeDict()
        
        // set everything else apart from plain text and id
        json["mimeType"] = JSON(histItem.mime)
        json["uri"] = JSON(histItem.path)
        json["title"] = JSON(NSURL(fileURLWithPath: histItem.path).lastPathComponent!)
        
    }
    
    func setDiMeDict() {
        json["@type"] = JSON("Document")
        json["type"] = JSON("http://www.hiit.fi/ontologies/dime/#Document")
    }
    
    func getDict() -> [String : AnyObject] {
        return json.dictionaryObject!
    }
}
