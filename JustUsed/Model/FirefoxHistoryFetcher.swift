//
//  FirefoxHistoryFetcher.swift
//  JustUsed
//
//  Created by Marco Filetti on 23/11/2015.
//  Copyright © 2015 HIIT. All rights reserved.
//

import Foundation
import Cocoa

class FirefoxHistoryFetcher: BrowserHistoryFetcher {

    private(set) var lastHistoryEntry: NSDate
    var lastDBFileUpdate: NSDate
    let browserType: BrowserType = .Safari
    
    /// Keeping firefox's db folder here since it changes from user to user
    private let dbFolder: NSURL
    
    required init?() {
        
        // initializes dates and performs first history check to update them
        lastHistoryEntry = NSDate()
        lastDBFileUpdate = NSDate.distantPast() // Initialise to be as early as possible.
        
        // if firefox db folder can't be found, fail initialization
        if let fdbf = FirefoxHistoryFetcher.getFirefoxDBFolder() {
            dbFolder = fdbf
        } else {
            dbFolder = NSURL()
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
        let lastTime = self.lastHistoryEntry.unixTime_μs
        let visits_query = "SELECT url, title, last_visit_date FROM moz_places WHERE last_visit_date > ? ORDER BY last_visit_date asc"
        if let visits_result = db.executeQuery(visits_query, withArgumentsInArray: ["\(lastTime)"]) {
            while visits_result.next() {
                let visits_dict = visits_result.resultDictionary()
                let visit_url = visits_dict["url"] as! String
                let visit_title = visits_dict["title"] as? String
                let visit_time = visits_dict["last_visit_date"] as! Int
                let visit_date = NSDate(fromUnixTime_μs: visit_time)
                self.lastHistoryEntry = visit_date
                let location = LocationSingleton.getCurrentLocation()
                new_urls.append(BrowserHistItem(browser: .Firefox, date: visit_date, url: visit_url, title: visit_title, location: location))
            }
        }
        db.close()
        
        return new_urls
    }
    
    /// Firefox implementation: return places.sqlite and places.sqlite-wal
    func getDBURLs() -> [NSURL] {
        
        let filenames: [String] = ["places.sqlite", "places.sqlite-wal", "places.sqlite-shm"]
        
        var retVal = [NSURL]()
        for filename in filenames {
            retVal.append(dbFolder.URLByAppendingPathComponent(filename))
        }
        
        // If places.sqlite does not exist, assume Firefox is not being used
        if !AppSingleton.fileManager.fileExistsAtPath(retVal[0].path!) {
            return [NSURL]()
        }
        
        // filter by keeping only existing paths
        retVal = retVal.filter({AppSingleton.fileManager.fileExistsAtPath($0.path!)})
        
        return retVal
    }
    
    
    // MARK: - Helpers
    
    /// Returns the location of the folder in which the Firefox databases are found.
    /// This is usually ~/Application\ Support/Firefox/Profiles/<id>.default.
    ///
    /// - returns: The url in which firefox's files are present, nil if nothing could be found
    static func getFirefoxDBFolder() -> NSURL? {
        let appSupportDir = NSFileManager.defaultManager().URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask)[0]
        let firefoxProfilesDir = appSupportDir.URLByAppendingPathComponent("Firefox/Profiles")
        let profilesEnumerator = NSFileManager.defaultManager().enumeratorAtURL(firefoxProfilesDir, includingPropertiesForKeys: [NSURLContentModificationDateKey, NSURLIsDirectoryKey], options: .SkipsSubdirectoryDescendants, errorHandler: nil)
        
        var newestDate = NSDate.distantPast()
        var newestURL: NSURL?
        
        // cycle through all files in firefox's profiles
        for element in profilesEnumerator! {
            let elURL = element as! NSURL
            var inVal: AnyObject?
            do {
                // only consider if it a directory
                try elURL.getResourceValue(&inVal, forKey: NSURLIsDirectoryKey)
                if let isDir = inVal as? Bool {
                    if isDir {
                        // check modification time, if newer than newest set URL
                        try elURL.getResourceValue(&inVal, forKey: NSURLContentModificationDateKey)
                        if let fileDate = inVal as? NSDate {
                            if fileDate.compare(newestDate) == .OrderedDescending {
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