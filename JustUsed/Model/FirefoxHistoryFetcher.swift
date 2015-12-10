//
//  FirefoxHistoryFetcher.swift
//  JustUsed
//
//  Created by Marco Filetti on 23/11/2015.
//  Copyright © 2015 HIIT. All rights reserved.
//

import Foundation
import Cocoa

//class FirefoxHistoryFetcher: BrowserHistoryFetcher {
class FirefoxHistoryFetcher {

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
        //historyCheck()
        
    }
    
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