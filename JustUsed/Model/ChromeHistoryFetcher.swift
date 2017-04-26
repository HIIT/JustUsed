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

class ChromeHistoryFetcher: BrowserHistoryFetcher {
    
    fileprivate(set) var lastHistoryEntry: Date
    var lastDBFileUpdate: Date
    let browserType: BrowserType = .Safari
    
    required init?() {
        
        // initializes dates and performs first history check to update them
        lastHistoryEntry = Date()
        lastDBFileUpdate = Date.distantPast // Initialise to be as early as possible.
        
        // If no valid urls exist, fail initialization
        if getDBURLs().count == 0 {
            return nil
        }
        
        // initialization succeeded, do first history check
        _ = historyCheck()
        
    }
    
    func getNewHistoryItemsFromDB(_ dbPath: String) -> [BrowserHistItem] {
        
        // Perform database read
        var new_urls = [BrowserHistItem]()
        let db = FMDatabase(path: dbPath)
        db?.open()
        let lastTime = self.lastHistoryEntry.ldapTime
        let urls_query = "SELECT url, title, last_visit_time FROM urls WHERE last_visit_time > ? ORDER BY last_visit_time asc"
        if let urls_result = db?.executeQuery(urls_query, withArgumentsIn: ["\(lastTime)"]) {
            while urls_result.next() {
                let urls_dict = urls_result.resultDictionary()
                let url = urls_dict!["url"] as! String
                let title = urls_dict!["title"] as! String
                let visit_time = urls_dict!["last_visit_time"] as! Int
                let visit_date = Date(fromLdapTime: visit_time)
                self.lastHistoryEntry = visit_date
                let location = LocationSingleton.getCurrentLocation()
                new_urls.append(BrowserHistItem(browser: .Chrome, date: visit_date, url: url, title: title, location: location))
            }
        }
        db?.close()
        
        return new_urls
    }
    
    /// Chrome implementation: return "History"
    func getDBURLs() -> [URL] {
        let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        
        let chromeDefaultDir = appSupportDir.appendingPathComponent("Google/Chrome/Default")
        
        let filenames: [String] = ["History"]
        
        var retVal = [URL]()
        for filename in filenames {
            retVal.append(chromeDefaultDir.appendingPathComponent(filename))
        }
        
        // If History does not exist, assume chrome is not being used
        if !AppSingleton.fileManager.fileExists(atPath: retVal[0].path) {
            return [URL]()
        }
        
        return retVal
    }
    
}
