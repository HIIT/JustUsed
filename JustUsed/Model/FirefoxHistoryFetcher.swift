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

class FirefoxHistoryFetcher: BrowserHistoryFetcher {

    fileprivate(set) var lastHistoryEntry: Date
    var lastDBFileUpdate: Date
    let browserType: BrowserType = .Safari
    
    /// Keeping firefox's db folder here since it changes from user to user
    fileprivate let dbFolder: URL!
    
    required init?() {
        
        // initializes dates and performs first history check to update them
        lastHistoryEntry = Date()
        lastDBFileUpdate = Date.distantPast // Initialise to be as early as possible.
        
        // if firefox db folder can't be found, fail initialization
        if let fdbf = FirefoxHistoryFetcher.getFirefoxDBFolder() {
            dbFolder = fdbf
        } else {
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
        let lastTime = self.lastHistoryEntry.unixTime_μs
        let visits_query = "SELECT url, title, last_visit_date FROM moz_places WHERE last_visit_date > ? ORDER BY last_visit_date asc"
        if let visits_result = db?.executeQuery(visits_query, withArgumentsIn: ["\(lastTime)"]) {
            while visits_result.next() {
                let visits_dict = visits_result.resultDictionary()
                let visit_url = visits_dict!["url"]! as! String
                let visit_title = visits_dict!["title"] as? String
                let visit_time = visits_dict!["last_visit_date"] as! Int
                let visit_date = Date(fromUnixTime_μs: visit_time)
                self.lastHistoryEntry = visit_date
                let location = LocationSingleton.getCurrentLocation()
                new_urls.append(BrowserHistItem(browser: .Firefox, date: visit_date, url: visit_url, title: visit_title, location: location))
            }
        }
        db?.close()
        
        return new_urls
    }
    
    /// Firefox implementation: return places.sqlite and places.sqlite-wal
    func getDBURLs() -> [URL] {
        
        let filenames: [String] = ["places.sqlite", "places.sqlite-wal", "places.sqlite-shm"]
        
        
        var retVal = [URL]()
        for filename in filenames {
            retVal.append(dbFolder.appendingPathComponent(filename))
        }
        
        // If places.sqlite does not exist, assume Firefox is not being used
        if !AppSingleton.fileManager.fileExists(atPath: retVal[0].path) {
            return [URL]()
        }
        
        // filter by keeping only existing paths
        retVal = retVal.filter({AppSingleton.fileManager.fileExists(atPath: $0.path)})
        
        return retVal
    }
    
    
    // MARK: - Helpers
    
    /// Returns the location of the folder in which the Firefox databases are found.
    /// This is usually ~/Application\ Support/Firefox/Profiles/<id>.default.
    ///
    /// - returns: The url in which firefox's files are present, nil if nothing could be found
    static func getFirefoxDBFolder() -> URL? {
        let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let firefoxProfilesDir = appSupportDir.appendingPathComponent("Firefox/Profiles")
        let profilesEnumerator = FileManager.default.enumerator(at: firefoxProfilesDir, includingPropertiesForKeys: [URLResourceKey.contentModificationDateKey, URLResourceKey.isDirectoryKey], options: .skipsSubdirectoryDescendants, errorHandler: nil)
        
        var newestDate = Date.distantPast
        var newestURL: URL?
        
        // cycle through all files in firefox's profiles
        for element in profilesEnumerator! {
            let elURL = element as! URL
            var inVal: AnyObject?
            do {
                // only consider if it a directory
                try (elURL as NSURL).getResourceValue(&inVal, forKey: URLResourceKey.isDirectoryKey)
                if let isDir = inVal as? Bool {
                    if isDir {
                        // check modification time, if newer than newest set URL
                        try (elURL as NSURL).getResourceValue(&inVal, forKey: URLResourceKey.contentModificationDateKey)
                        if let fileDate = inVal as? Date {
                            if fileDate.compare(newestDate) == .orderedDescending {
                                newestURL = elURL
                                newestDate = fileDate
                            }
                        }
                    }
                }
            } catch {
                AppSingleton.log.error("Failed to fetch information for \(elURL.path)")
            }
        }
        return newestURL
    }
}
