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
        let lastTime = self.lastHistoryEntry.timeIntervalSinceReferenceDate as Double
        let visits_query = "SELECT history_item, visit_time, title FROM history_visits WHERE visit_time > ? ORDER BY visit_time asc"
        if let visits_result = db.executeQuery(visits_query, withArgumentsInArray: ["\(lastTime)"]) {
            while visits_result.next() {
                let visits_dict = visits_result.resultDictionary()
                let visit_id = visits_dict["history_item"] as! NSNumber
                let visit_title = visits_dict["title"] as? String
                let visit_time = visits_dict["visit_time"] as! NSNumber
                let visit_date = NSDate(timeIntervalSinceReferenceDate: visit_time as NSTimeInterval)
                self.lastHistoryEntry = visit_date
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
        
        // filter by keeping only existing paths
        retVal = retVal.filter({AppSingleton.fileManager.fileExistsAtPath($0.path!)})
        
        return retVal
    }
}