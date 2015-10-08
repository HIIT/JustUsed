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
    var location: MyLocation?
    /// Index used by spotlight (an index refers to a specific item in spotlight's history)
    let index: Int
    /// Mime type
    let mime: String
}

func ==(lhs:SpotlightHistItem, rhs: SpotlightHistItem) -> Bool {
    return lhs.path == rhs.path && lhs.index == rhs.index && lhs.mime == rhs.mime
}

extension NSMetadataItem {
    
    /// Returns a struct representing this metadataitem
    func makeHistItem(withIndex index: Int) -> SpotlightHistItem {
        let path = self.valueForKey(kMDItemPath as String)!.description
        let index = index
        
        // mime type
        var mime: String?
        let pathURL = NSURL(fileURLWithPath: path)
        let UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathURL.pathExtension!, nil)
        let MIMEType = UTTypeCopyPreferredTagWithClass(UTI!.takeRetainedValue(), kUTTagClassMIMEType)
        var isDir = ObjCBool(false)
        if let mimet = MIMEType {
            mime = mimet.takeRetainedValue() as String
        } else if NSFileManager.defaultManager().fileExistsAtPath(path, isDirectory: &isDir) {
            if isDir {
                mime = "application/x-directory"
            } else {
                // if the file exists but it's not a directory and has no known mime type
                var foundEncoding: UInt = 0
                if let _ = try? NSString(contentsOfURL: NSURL(fileURLWithPath: path), usedEncoding: &foundEncoding) {
                    mime = "text/plain"
                } else {
                    mime = "application/octet-stream"
                }
            }
        }
        // end mime type
        
        let location = LocationSingleton.getCurrentLocation()
        
        return SpotlightHistItem(lastAccessDate: NSDate(), path: path, location: location, index: index, mime: mime!)
    }
}

class SpotlightTracker: NSObject {
    
    /// Won't re-add a last used item if it is already used within the last x seconds
    let kMinSeconds = JustUsedConstants.kSpotlightMinSeconds
    
    dynamic var query: NSMetadataQuery?
    
    /// Stores all items found by spotlight. Items are stored in the same index used by spotlight, so item 0 in this list correponds to the first item found after starting the application
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
        let predicateFormat = "kMDItemLastUsedDate >= %@"
        var predicateToRun = NSPredicate(format: predicateFormat, argumentArray: [startDate])
        
        // Now, we don't want to include email messages in the result set, so add in an AND that excludes them
        let emailExclusionPredicate = NSPredicate(format: "(kMDItemContentType != 'com.apple.mail.emlx') && (kMDItemContentType != 'public.vcard')", argumentArray: nil)
        predicateToRun = NSCompoundPredicate(andPredicateWithSubpredicates: [predicateToRun, emailExclusionPredicate])
        
        query?.predicate = predicateToRun
        query?.startQuery()
    }
    
    @objc func queryUpdated(notification: NSNotification) {
        query?.enumerateResultsUsingBlock(updateBlock)
    }
    
    func updateBlock(input: AnyObject!, index: Int, boolPoint: UnsafeMutablePointer<ObjCBool>) {
        let inputVal = input as! NSMetadataItem
        let newHistItem = inputVal.makeHistItem(withIndex: index)
        if index >= allItems.count {
            for delegate in SpotlightHistoryUpdateDelegates! {
                delegate.newSpotlightData(newHistItem)
            }
            allItems.append(newHistItem)
        } else {
            // Only re-add items if first time that it was opened was before kMinSeconds from now
            let shiftedDate = NSDate().dateByAddingTimeInterval(-kMinSeconds)
            let previousDate = allItems[index].lastAccessDate
            if shiftedDate.compare(previousDate) == NSComparisonResult.OrderedDescending {
                allItems[index].lastAccessDate = NSDate()
                for delegate in SpotlightHistoryUpdateDelegates! {
                    delegate.newSpotlightData(newHistItem)
                }
            }
        }
    }
    
}