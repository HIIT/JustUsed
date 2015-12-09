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

/// Implementers of this protocol can receive updates regarding newer history items.
protocol SafariHistoryUpdateDelegate {
    
    /// Notifies an update to history items
    /// @param items An array of string containing new urls of new items just added to the history
    func newHistoryItems(newURLs: [SafariHistItem])
}

/// A new safari history item will be returned as this to the delegate
struct SafariHistItem: Equatable {
    let date: NSDate
    let url: String
    let title: String?
    let location: Location?
}

func ==(lhs: SafariHistItem, rhs: SafariHistItem) -> Bool {
    return lhs.url == rhs.url && lhs.date.compare(rhs.date) == NSComparisonResult.OrderedSame && lhs.title == rhs.title
}

/// Manages safari history by querying the History.db file in /Libary/Safari
/// Makes a copy for reading if file has been updated. Checks every x seconds (kSafariHistoryCheckTime)
class SafariHistoryFetcher {
    
    /// Checks for an update to the database after this amount of seconds
    static let kSafariHistoryCheckTime = 10.0
    
    private var checkTimer: NSTimer
    private var autoFetcher: SafariAutoFetcher
    
    /// Creates a monitor. Set a delegate to receive updates after creating this object.
    /// @param updateDelegate The object that will be notified of new history items
    required init() {
        autoFetcher = SafariAutoFetcher()
        checkTimer = NSTimer(timeInterval: SafariHistoryFetcher.kSafariHistoryCheckTime, target: autoFetcher, selector: "timerFire:", userInfo: nil, repeats: true)
        NSRunLoop.currentRunLoop().addTimer(checkTimer, forMode: NSRunLoopCommonModes)
        checkTimer.valid
    }
    
    /// A delegate adds itself using this in order to receive updates regarding new history urls
    func addUpdateDelegate(updateDelegate: SafariHistoryUpdateDelegate) {
        autoFetcher.addUpdateDelegate(updateDelegate)
    }
    
    /// Nested class to handle timer updates and calls to delegate
    private class SafariAutoFetcher: NSObject {
        
        /// Last time the safari database (on disk) was marked as read.
        var lastDBFileUpdate: NSDate
    
        /// Time that last history item has been communicated to delegate. We want to communicate new history items which are > this date.
        var lastUpdateTime: NSDate
        
        private var updateDelegates: [SafariHistoryUpdateDelegate]?
        
        /// Ref to filemanager for convenience
        let fileManager = NSFileManager.defaultManager()
        
        required override init() {
            lastUpdateTime = NSDate()
            lastDBFileUpdate = NSDate.distantPast() // Initialise to be as early as possible.
            super.init()
            historyCheck()
        }
        
        @objc func timerFire(timer: NSTimer) {
            historyCheck()
        }
        
        func addUpdateDelegate(newDelegate: SafariHistoryUpdateDelegate) {
            if updateDelegates == nil {
                updateDelegates = [SafariHistoryUpdateDelegate]()
            }
            updateDelegates!.append(newDelegate)
        }
        
        /// MARK: Main function
        
        /// Update history. It is called automatically after creation and every kSafariHistoryCheckTime seconds
        /// Copies current database to temporary directory because safari keeps lock on it (maybe fmdb / sqlite3 has a bug and we can't even read without copying).
        func historyCheck() {
            //let oriHistURL = NSURL(fileURLWithPath: NSHomeDirectory()).URLByAppendingPathComponent("Library/Safari/History.db")
            //let oriHistPath = oriHistURL.absoluteString
            
            var err: NSError?  // Note: reusing same error here
            
            // We proceed only if the date database was modified is newer than the last date
            let dbTime = latestDBTime()
            if dbTime.compare(lastDBFileUpdate) == NSComparisonResult.OrderedDescending {
                lastDBFileUpdate = dbTime
            } else {
                return
            }
            
            let tempPaths = copyFiles()  // copy files and get db file path
            let tempDBpath = tempPaths[0]
            
            // Perform database read
            var new_urls = [SafariHistItem]()
            let db = FMDatabase(path: tempDBpath)
            db.open()
            let lastTime = self.lastUpdateTime.timeIntervalSinceReferenceDate as Double
            self.lastUpdateTime = NSDate()
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
                        new_urls.append(SafariHistItem(date: visit_date, url: item_url, title: visit_title, location: location))
                    }
                }
            }
            db.close()
            
            // Remove temporary files
            for filePath in tempPaths {
                do {
                    try fileManager.removeItemAtPath(filePath)
                    //AppSingleton.log.debug("succesfully removed")
                } catch let error as NSError {
                    err = error
                    AppSingleton.log.error("Something went wrong while removing old databases: \(err.debugDescription)")
                }
            }
            
            if new_urls.count > 0 {
                for updateDelegate in updateDelegates! {
                    updateDelegate.newHistoryItems(new_urls)
                }
            }
        }
        
        /// MARK: Helper functions
        
        /// Returns the latest time that either the .db or .db-wal file was modified
        func latestDBTime() -> NSDate {
            var dates = [NSDate]()
            
            for fileUrl in getDBURLs() {
                
                var inVal: AnyObject?
                var myError: NSError?
                do {
                    try fileUrl.getResourceValue(&inVal, forKey: NSURLContentModificationDateKey)
                } catch let error as NSError {
                    myError = error
                }
                if let error = myError {
                    AppSingleton.log.error("Something went wrong while reading db files: \(error.debugDescription)")
                }
                if let fileDate = inVal as? NSDate {
                    dates.append(fileDate)
                }
                
            }
            dates.sortInPlace({ $0.compare($1) == NSComparisonResult.OrderedDescending })
            return dates[0]
        }
        
        /// Copies both .db and .db-wal files to temporary directory
        /// Returns all paths, with the first one being the .db file
        func copyFiles() -> [String] {
            
            var allPaths = [String]()  // paths will be put here
            // Create temporary directory and delete previous temporary file (if present)
            let tempURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("hiit.JustUsed")
            _ = tempURL.path!
            var err: NSError?
            do {
                try fileManager.createDirectoryAtURL(tempURL, withIntermediateDirectories: true, attributes: nil)
                //AppSingleton.log.debug("directory created succesfully")
            } catch let error as NSError {
                err = error
            }
            
            // Copy files
            for dbPathURL in getDBURLs() {
                let filenameURL = dbPathURL
                let tempDataFileURL = tempURL.URLByAppendingPathComponent("Safari_copied_\(filenameURL.lastPathComponent!)")
                let tempDataFile = tempDataFileURL.path!
                allPaths.append(tempDataFile)
                
                if fileManager.fileExistsAtPath(tempDataFile) {
                    //AppSingleton.log.debug("file exists already")
                    do {
                        try fileManager.removeItemAtURL(tempDataFileURL)
                        //AppSingleton.log.debug("succesfully removed")
                    } catch let error as NSError {
                        err = error
                    }
                }
                
                // Copy database
                if fileManager.fileExistsAtPath(dbPathURL.path!) {
                    do {
                        try fileManager.copyItemAtURL(dbPathURL, toURL: tempDataFileURL)
                        //AppSingleton.log.debug("file created")
                    } catch let error as NSError {
                        err = error
                        AppSingleton.log.error(err?.description)
                    }
                }
            }
            
            return allPaths
        }
        
        /// Gets path of both .db and .db-wal files, in an array of String
        func getDBURLs() -> [NSURL] {
            let safariLibURL = NSURL(fileURLWithPath: NSHomeDirectory()).URLByAppendingPathComponent("Library/Safari")
            
            let filenames: [String] = ["History.db", "History.db-wal", "History.db-shm"]
            
            var retVal = [NSURL]()
            for filename in filenames {
                retVal.append(safariLibURL.URLByAppendingPathComponent(filename))
            }
            return retVal
        }
    }
}