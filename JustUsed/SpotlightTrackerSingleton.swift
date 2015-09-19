//
//  SpotlightTrackerSingleton.swift
//  JustUsed
//
//  Created by Marco Filetti on 13/08/2015.
//  Copyright (c) 2015 HIIT. All rights reserved.
//

import Foundation
import Cocoa

/// Keeps track of the spotlight tracker, of which we should have only one instance at a time
class SpotlightTrackerSingleton {
    private static let _fileTracker = SpotlightTracker()
    
    static func getFileTracker() -> SpotlightTracker {
        return SpotlightTrackerSingleton._fileTracker
    }
}

/// Protocol to notify a delegate that some data was updated (currently used to reload table)
protocol SpotlightTrackerDelegate {
    
    /// Tells the delegate that new data is available
    func newSpotlightData()
}

class SpotlightTracker: NSObject, NSTableViewDataSource {
    
    /// Won't re-add a last used item if it is already used within the last x seconds
    let kMinSeconds = 300.0
    
    dynamic var query: NSMetadataQuery?
    
    var lutimes = [String]()
    var lupaths = [String]()
    var integers = [String]()
    var locations = [String]()
    var booleans = [String]()
    var dates = [NSDate]()
    var mimes = [String]()
    
    var initalLocation = ""
    
    var newSpotlightDataDelegate: SpotlightTrackerDelegate?
    
    required override init() {
        self.initalLocation = LocationSingleton.getLocationString()
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
    
    func setDelegate(newDelegate: SpotlightTrackerDelegate) {
        self.newSpotlightDataDelegate = newDelegate
    }
    
    @objc func queryUpdated(notification: NSNotification) {
        query?.enumerateResultsUsingBlock(updateBlock)
        newSpotlightDataDelegate?.newSpotlightData()
    }
    
    func updateBlock(input: AnyObject!, index: Int, boolPoint: UnsafeMutablePointer<ObjCBool>) {
        let inputVal = input as! NSMetadataItem
        if index >= dates.count {
            lutimes.append(NSDate().descriptionWithLocale(NSLocale.currentLocale()))
            dates.append(NSDate())
            let path = inputVal.valueForKey(kMDItemPath as String)!.description
            lupaths.append(path)
            integers.append(index.description)
            let pathURL = NSURL(fileURLWithPath: path)
            let UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathURL.pathExtension!, nil)
            let MIMEType = UTTypeCopyPreferredTagWithClass(UTI!.takeRetainedValue(), kUTTagClassMIMEType)
            var isDir = ObjCBool(false)
            if let mimet = MIMEType {
                mimes.append(mimet.takeRetainedValue() as String)
            } else if NSFileManager.defaultManager().fileExistsAtPath(path, isDirectory: &isDir) {
                if isDir {
                    mimes.append("application/x-directory")
                } else {
                    // if the file exists but it's not a directory and has no known mime type
                    var foundEncoding: UInt = 0
                    if let foundString = try? NSString(contentsOfURL: NSURL(fileURLWithPath: path), usedEncoding: &foundEncoding) {
                        mimes.append("text/plain")
                    } else {
                        mimes.append("application/octet-stream")
                    }
                }
            }
            locations.append(LocationSingleton.getLocationString())
            if boolPoint.memory {
                booleans.append("true")
            } else {
                booleans.append("false")
            }
        } else {
            // Only re-add items if first time that it was opened was before kMinSeconds from now
            let shiftedDate = NSDate().dateByAddingTimeInterval(-kMinSeconds)
            let previousDate = dates[index]
            if shiftedDate.compare(previousDate) == NSComparisonResult.OrderedDescending {
                lutimes.append(NSDate().description)
                let path = inputVal.valueForKey(kMDItemPath as String)!.description
                lupaths.append(path)
                integers.append(index.description)
                let pathURL = NSURL(fileURLWithPath: path)
                let UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathURL.pathExtension!, nil)
                let MIMEType = UTTypeCopyPreferredTagWithClass(UTI!.takeRetainedValue(), kUTTagClassMIMEType)
                var isDir = ObjCBool(false)
                if let mimet = MIMEType {
                    mimes.append(mimet.takeRetainedValue() as String)
                } else if NSFileManager.defaultManager().fileExistsAtPath(path, isDirectory: &isDir) {
                    if isDir {
                        mimes.append("application/x-directory")
                    } else {
                        // if the file exists but it's not a directory and has no known mime type
                        var foundEncoding: UInt = 0
                        if let foundString = try? NSString(contentsOfURL: NSURL(fileURLWithPath: path), usedEncoding: &foundEncoding) {
                            mimes.append("text/plain")
                        } else {
                            mimes.append("application/octet-stream")
                        }
                    }
                }
                locations.append(LocationSingleton.getLocationString())
                dates[index] = NSDate()  // update first opening time when re-adding
            }
            if boolPoint.memory {
                booleans.append("true")
            } else {
                booleans.append("false")
            }
        }
    }
    
    /// MARK: Static table data source
    func numberOfRowsInTableView(aTableView: NSTableView) -> Int {
        return lutimes.count
    }
    
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        if tableColumn!.identifier == JustUsedConstants.kLastUsedDateTitle {
            return lutimes[row]
        } else if tableColumn!.identifier == JustUsedConstants.kPathTitle {
            return lupaths[row]
        } else if tableColumn!.identifier == JustUsedConstants.kIndexTitle {
            return integers[row]
        } else if tableColumn!.identifier == JustUsedConstants.kLocTitle {
            return locations[row]
        } else if tableColumn!.identifier == JustUsedConstants.kMimeType {
            return mimes[row]
        } else {
            return booleans[row]
        }
    }
    
}