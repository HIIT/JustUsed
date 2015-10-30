//
//  RecentPlistTracker.swift
//  JustUsed
//
//  Created by Marco Filetti on 30/10/2015.
//  Copyright © 2015 HIIT. All rights reserved.
//

import Foundation

/// Tracks recent documents by looking at *LSSharedFileList.plist files found in ~Library/Preferences, which is the method
/// used by Yosemite to save recently opened documents
class RecentPlistTracker: RecentDocumentsTracker {
    
    /// Convenience file manager
    private var fm = NSFileManager.defaultManager()
    
    /// Plists' last modification date is stored in this dictionary
    private var allPlists = [NSURL: NSDate]()
    
    /// Files are tracked every this amount of seconds
    private let kPlistCheckTime = 5.0
    
    required init() {
        super.init()
        
        // Initialise allPlists by looking at all files in the Library/Preferences directory
        for tuple in getAllPlists() {
            allPlists[tuple.sflUrl] = tuple.modDate
        }
        
        // Start timer
        let checkTimer = NSTimer(timeInterval: kPlistCheckTime, target: self, selector: "timerHit:", userInfo: nil, repeats: true)
        NSRunLoop.currentRunLoop().addTimer(checkTimer, forMode: NSRunLoopCommonModes)
    }
    
    /// Check if any recent document plist has been modified since last time the timer hit
    @objc private func timerHit(theTimer: NSTimer) {
        for tuple in getAllPlists() {
            
            // if previous item exists, check date, otherwise add it
            if let previousModDate = allPlists[tuple.sflUrl] {
                // check if the just found modification date is more recent than the last found one
                if tuple.modDate.compare(previousModDate) == NSComparisonResult.OrderedDescending {
                    allPlists[tuple.sflUrl] = tuple.modDate
                    if let newItem = fetchMostRecentDoc(fromFile: tuple.sflUrl, date: tuple.modDate) {
                        for upDel in recentDocumentUpdateDelegates {
                            upDel.newRecentDocument(newItem)
                        }
                    }
                }
            } else {
                allPlists[tuple.sflUrl] = tuple.modDate
                if let newItem = fetchMostRecentDoc(fromFile: tuple.sflUrl, date: tuple.modDate) {
                    for upDel in recentDocumentUpdateDelegates {
                        upDel.newRecentDocument(newItem)
                    }
                }
            }
        }
    }
    
    /// Extract the most recent opened document from the given recent documents plist
    ///
    /// - parameter fromFile: The path of the file on disk
    /// - parameter date: The date on which the recend document was added
    /// - returns: A spotlight hist item representing the most recent opened document in the sfl
    private func fetchMostRecentDoc(fromFile filePath: NSURL, date: NSDate) -> RecentDocItem? {
        
        guard let sfl = NSDictionary(contentsOfURL: filePath),
                  recents = sfl["RecentDocuments"],
                  objects = recents["CustomListItems"],
                  mostrecentpossiblebook = objects[0]["Bookmark"] as? NSData,
                  abookdict = NSURL.resourceValuesForKeys([NSURLPathKey], fromBookmarkData: mostrecentpossiblebook)
                  else {
            return nil
        }
        let path = abookdict[NSURLPathKey]! as! String
        let docUrl = NSURL(fileURLWithPath: path)
        let rangeOfLSSharedFileList = filePath.lastPathComponent!.rangeOfString(".LSSharedFileList")
        let docSource = filePath.lastPathComponent!.substringToIndex(rangeOfLSSharedFileList!.startIndex)
        let location = LocationSingleton.getCurrentLocation()
        return RecentDocItem(lastAccessDate: date, path: docUrl.path!, location: location, mime: docUrl.getMime()!, source: docSource)
    }
    
    
    /// Returns all plist files related to recents documents and their last modification date in a tuple
    private func getAllPlists() -> [(sflUrl: NSURL, modDate: NSDate)] {
        var retVal = [(sflUrl: NSURL, modDate: NSDate)]()
        
        let preferencesDir = NSURL(fileURLWithPath: NSHomeDirectory()).URLByAppendingPathComponent("Library/Preferences")
        do {
            let allPrefs = try fm.contentsOfDirectoryAtURL(preferencesDir, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions())
            let sfls = allPrefs.filter({$0.lastPathComponent!.rangeOfString("LSSharedFileList.plist") != nil})
            
            for sfl in sfls {
                var inVal: AnyObject?
                do {
                    try sfl.getResourceValue(&inVal, forKey: NSURLContentModificationDateKey)
                    if let fileDate = inVal as? NSDate {
                        retVal.append((sfl, fileDate))
                    }
                } catch let error as NSError {
                      AppSingleton.log.error("Error while reading modification date: \(error)")
                }
                
            }
        } catch let error {
            AppSingleton.log.error("Error while reading preferences: \(error)")
        }
        
        return retVal
        
    }
}