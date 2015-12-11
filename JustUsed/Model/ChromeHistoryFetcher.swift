//
//  ChromeHistoryFetcher.swift
//  JustUsed
//
//  Created by Marco Filetti on 23/11/2015.
//  Copyright © 2015 HIIT. All rights reserved.
//

import Foundation
import Cocoa

class ChromeHistoryFetcher: BrowserHistoryFetcher {
    
    private(set) var lastHistoryEntry: NSDate
    var lastDBFileUpdate: NSDate
    let browserType: BrowserType = .Safari
    
    required init?() {
        
        // initializes dates and performs first history check to update them
        lastHistoryEntry = NSDate()
        lastDBFileUpdate = NSDate.distantPast() // Initialise to be as early as possible.
        
        // If no valid urls exist, fail initialization
        if getDBURLs().count == 0 {
            return nil
        }
        
        // initialization succeeded, do first history check
        historyCheck()
        
    }
    
    func getNewHistoryItemsFromDB(dbPath: String) -> [BrowserHistItem] {
        
        // Perform database read
        var new_urls = [BrowserHistItem]()
        let db = FMDatabase(path: dbPath)
        db.open()
        let lastTime = self.lastHistoryEntry.ldapTime
        let urls_query = "SELECT url, title, last_visit_time FROM urls WHERE last_visit_time > ? ORDER BY last_visit_time asc"
        if let urls_result = db.executeQuery(urls_query, withArgumentsInArray: ["\(lastTime)"]) {
            while urls_result.next() {
                let urls_dict = urls_result.resultDictionary()
                let url = urls_dict["url"] as! String
                let title = urls_dict["title"] as? String
                let visit_time = urls_dict["last_visit_time"] as! Int
                let visit_date = NSDate(fromLdapTime: visit_time)
                self.lastHistoryEntry = visit_date
                let location = LocationSingleton.getCurrentLocation()
                new_urls.append(BrowserHistItem(browser: .Chrome, date: visit_date, url: url, title: title, location: location))
            }
        }
        db.close()
        
        return new_urls
    }
    
    /// Chrome implementation: return "History"
    func getDBURLs() -> [NSURL] {
        let appSupportDir = NSFileManager.defaultManager().URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask)[0]
        
        let chromeDefaultDir = appSupportDir.URLByAppendingPathComponent("Google/Chrome/Default")
        
        let filenames: [String] = ["History"]
        
        var retVal = [NSURL]()
        for filename in filenames {
            retVal.append(chromeDefaultDir.URLByAppendingPathComponent(filename))
        }
        
        // If History does not exist, assume chrome is not being used
        if !AppSingleton.fileManager.fileExistsAtPath(retVal[0].path!) {
            return [NSURL]()
        }
        
        return retVal
    }
    
}
