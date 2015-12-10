//
//  SafariHistoryFetcher.swift
//  JustUsed
//
//  Created by Marco Filetti on 13/08/2015.
//  Copyright (c) 2015 HIIT. All rights reserved.
//

import Foundation
import Cocoa
import CoreLocation

/// Manages safari history by querying the History.db file in /Libary/Safari
/// Makes a copy for reading if file has been updated. Checks every x seconds (kSafariHistoryCheckTime)
class SafariHistoryFetcher: BrowserHistoryFetcher {
    
    private(set) var lastHistoryEntry: NSDate
    var lastDBFileUpdate: NSDate
    let browserType: BrowserType = .Safari
    
    required init?() {
        
        // initializes dates and performs first history check to update them
        lastHistoryEntry = NSDate()
        lastDBFileUpdate = NSDate.distantPast() // Initialise to be as early as possible.
        
        // If not valid urls exist, fail initialization
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
        let lastTime = self.lastHistoryEntry.timeIntervalSinceReferenceDate as Double
        self.lastHistoryEntry = NSDate()
        let visits_query = "SELECT history_item, visit_time, title FROM history_visits WHERE visit_time > ?"
        if let visits_result = db.executeQuery(visits_query, withArgumentsInArray: ["\(lastTime)"]) {
            while visits_result.next() {
                let visits_dict = visits_result.resultDictionary()
                let visit_id = visits_dict["history_item"] as! NSNumber
                var visit_title: String?
                if let newTitle = visits_dict["title"] as? String {
                    visit_title = newTitle
                }
                let visit_time = visits_dict["visit_time"] as! NSNumber
                let visit_date = NSDate(timeIntervalSinceReferenceDate: visit_time as NSTimeInterval)
                let item_query = "SELECT url FROM history_items WHERE id = ?"
                let item_result = db.executeQuery(item_query, withArgumentsInArray: [visit_id])
                while item_result.next() {
                    let item_dict = item_result.resultDictionary()
                    let item_url = item_dict["url"] as! String
                    let location = LocationSingleton.getCurrentLocation()
                    new_urls.append(BrowserHistItem(browser: .Safari, date: visit_date, url: item_url, title: visit_title, location: location))
                }
            }
        }
        db.close()
        
        return new_urls
    }
    
    /// Safari implementation: gets path of both .db, .db-wal and .db-shm files
    func getDBURLs() -> [NSURL] {
        let safariLibURL = NSURL(fileURLWithPath: NSHomeDirectory()).URLByAppendingPathComponent("Library/Safari")
        
        let filenames: [String] = ["History.db", "History.db-wal", "History.db-shm"]
        
        var retVal = [NSURL]()
        for filename in filenames {
            retVal.append(safariLibURL.URLByAppendingPathComponent(filename))
        }
        
        // If History.db does not exist, assume Safari is not being used
        if !AppSingleton.fileManager.fileExistsAtPath(retVal[0].path!) {
            return [NSURL]()
        }
        
        return retVal
    }
}