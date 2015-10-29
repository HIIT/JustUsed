//
//  SpotlightTrackerSingleton.swift
//  JustUsed
//
//  Created by Marco Filetti on 13/08/2015.
//  Copyright (c) 2015 HIIT. All rights reserved.
//

import Foundation
import Cocoa

/// Protocol to notify a delegate that some data was updated (currently used to reload table)
protocol SpotlightHistoryUpdateDelegate {
    
    /// Tells the delegate that new data is available
    func newSpotlightData(newItem: SpotlightHistItem)
}

/// New spotlight history items are represented by this struct
struct SpotlightHistItem: Equatable {
    /// Date that this item was last accessed
    var lastAccessDate: NSDate
    /// Path of this file on disk
    let path: String
    /// Location when this file was last opened, if available
    var location: Location?
    /// Mime type
    let mime: String
    /// What program opened this file
    let source: String
}

func ==(lhs:SpotlightHistItem, rhs: SpotlightHistItem) -> Bool {
    return lhs.path == rhs.path && lhs.source == rhs.source && lhs.mime == rhs.mime
}

class SpotlightTracker: NSObject {
    
    /// Won't re-add a last used item if it is already used within the last x seconds
    let kMinSeconds = JustUsedConstants.kSpotlightMinSeconds
    
    dynamic var query: NSMetadataQuery?
    
    /// Stores all items found by spotlight. Items are stored in order, so item 0 in this list correponds to the first item found after starting the application
    private var allItems = [SpotlightHistItem]()
    
    private var SpotlightHistoryUpdateDelegates: [SpotlightHistoryUpdateDelegate]?
    
    func addSpotlightDataDelegate(newSpotlightDataDelegate: SpotlightHistoryUpdateDelegate) {
        if SpotlightHistoryUpdateDelegates == nil {
            SpotlightHistoryUpdateDelegates = [SpotlightHistoryUpdateDelegate]()
        }
        SpotlightHistoryUpdateDelegates?.append(newSpotlightDataDelegate)
    }
    
    required override init() {
        super.init()
        
        query = NSMetadataQuery()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "queryUpdated:", name: NSMetadataQueryDidUpdateNotification, object: query)
        
        query?.searchScopes = [NSMetadataQueryUserHomeScope]
        
        let startDate = NSDate()
        let predicateFormat = "kMDItemFSContentChangeDate >= %@"
        var predicateToRun = NSPredicate(format: predicateFormat, argumentArray: [startDate])
        
        // Now, we don't want to include email messages in the result set, so add in an AND that excludes them
        let emailExclusionPredicate = NSPredicate(format: "(kMDItemContentType != 'com.apple.mail.emlx') && (kMDItemContentType != 'public.vcard')", argumentArray: nil)
        
        // Only look for files that end in .sfl
        let extensionPredicate = NSPredicate(format: "%K ENDSWITH %@", NSMetadataItemFSNameKey, ".sfl")
        
        predicateToRun = NSCompoundPredicate(andPredicateWithSubpredicates: [predicateToRun, emailExclusionPredicate, extensionPredicate])
        
        // Exclude top-level sfl files
        let excludedFiles = ["com.apple.LSSharedFileList.RecentDocuments.sfl",
            "com.apple.LSSharedFileList.RecentApplications.sfl",
            "com.apple.LSSharedFileList.RecentHosts.sfl",
            "com.apple.LSSharedFileList.FavoriteItems.sfl",
            "com.apple.LSSharedFileList.ProjectsItems.sfl",
            "com.apple.LSSharedFileList.RecentServers.sfl",
            "com.apple.LSSharedFileList.ApplicationRecentDocuments.sfl"]
        
        for exclFile in excludedFiles {
            let exclPredicate = NSPredicate(format: "%K != %@", NSMetadataItemFSNameKey, exclFile)
            predicateToRun = NSCompoundPredicate(andPredicateWithSubpredicates: [predicateToRun, exclPredicate])
        }
        
        query?.predicate = predicateToRun
        query?.startQuery()
    }
    
    @objc func queryUpdated(notification: NSNotification) {
        query?.enumerateResultsUsingBlock(updateBlock)
    }
    
    func updateBlock(input: AnyObject!, index: Int, boolPoint: UnsafeMutablePointer<ObjCBool>) {
        let inputVal = input as! NSMetadataItem
        guard let path = inputVal.valueForKey(kMDItemPath as String), date = inputVal.valueForKey(NSMetadataItemFSContentChangeDateKey as String), newHistItem = fetchMostRecentDoc(fromSfl: NSURL(fileURLWithPath: path as! String), date: date as! NSDate) else {
            return
        }
        if !allItems.contains(newHistItem) {
            for delegate in SpotlightHistoryUpdateDelegates! {
                delegate.newSpotlightData(newHistItem)
            }
            allItems.append(newHistItem)
        } else {
            let previousItemIndex = allItems.indexOf(newHistItem)!
            // Only re-add items if first time that it was opened was before kMinSeconds from now
            let shiftedDate = NSDate().dateByAddingTimeInterval(-kMinSeconds)
            let previousDate = allItems[previousItemIndex].lastAccessDate
            if shiftedDate.compare(previousDate) == NSComparisonResult.OrderedDescending {
                allItems[previousItemIndex].lastAccessDate = NSDate()
                for delegate in SpotlightHistoryUpdateDelegates! {
                    delegate.newSpotlightData(newHistItem)
                }
            }
        }
    }
    
    /// Extract the most recent opened document from the given shared file list
    ///
    /// - parameter fromSfl: The path of the sfl file on disk
    /// - returns: A spotlight hist item representing the most recent opened document in the sfl
    private func fetchMostRecentDoc(fromSfl filePath: NSURL, date: NSDate) -> SpotlightHistItem? {
        
        let sfl = NSDictionary(contentsOfURL: filePath)!
        
        let objects = sfl["$objects"]!
        
        // create tuples for each element in the sharedfilelist, first item is count, second path
        var tuples = [(count: Int, path: String)]()
        var i = 0
        while i < objects.count! {
            // seek order (int) which comes before bookmark
            if let odict = objects[i] as? NSDictionary, order = odict["order"] {
                if let cnt = order as? Int {
                    
                    // seek bookmark and associate it to previously found order
                    while i < objects.count! - 1 {
                        i++
                        
                        if let possiblebook = objects[i] as? NSData, abookdict = NSURL.resourceValuesForKeys([NSURLPathKey], fromBookmarkData: possiblebook) {
                            
                            tuples.append((count: cnt, path: abookdict[NSURLPathKey]! as! String))
                            break
                            
                        }
                        
                    }
                    
                }
            }
            i++
        }
        if tuples.count > 0 {
            // sort tuples by count in ascending order, take first item
            tuples = tuples.sort {$0.0 < $1.0}
            // most recent document URL
            let docUrl = NSURL(fileURLWithPath: tuples[0].path)
            // get application name by removing extension
            let docSource = filePath.URLByDeletingPathExtension!.lastPathComponent!
            let location = LocationSingleton.getCurrentLocation()
            return SpotlightHistItem(lastAccessDate: date, path: docUrl.path!, location: location, mime: docUrl.getMime()!, source: docSource)
        } else {
            return nil
        }
    }
}