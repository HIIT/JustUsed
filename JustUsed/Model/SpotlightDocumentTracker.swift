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

/// SpotlightTracker checks all recently modified .sfl files (where recently opened documents are stored by OS X El Capitan) using spotlight.
class SpotlightDocumentTracker: RecentDocumentsTracker {
    
    /// Won't re-add a last used item if it is already used within the last x seconds
    let kMinSeconds = JustUsedConstants.kSpotlightMinSeconds
    
    dynamic var query: NSMetadataQuery?
    
    /// Stores all recent documents found. Items are stored in order, so item 0 in this list correponds to the first item found after starting the application
    private var allItems = [RecentDocItem]()
    
    
    required init() {
        super.init()
        
        query = NSMetadataQuery()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(queryUpdated(_:)), name: NSMetadataQueryDidUpdateNotification, object: query)
        
        query?.searchScopes = [NSMetadataQueryUserHomeScope]
        
        let startDate = NSDate()
        let predicateFormat = "kMDItemFSContentChangeDate >= %@"
        var predicateToRun = NSPredicate(format: predicateFormat, argumentArray: [startDate])
        
        // Now, we don't want to include email messages in the result set, so add in an AND that excludes them
        let emailExclusionPredicate = NSPredicate(format: "(kMDItemContentType != 'com.apple.mail.emlx') && (kMDItemContentType != 'public.vcard')", argumentArray: nil)
        
        if AppSingleton.isElCapitan {
            
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
                
        } else {
            
            // Only look for files that end with LSSharedFileList.plist
            let sflPredicate = NSPredicate(format: "%K ENDSWITH %@", NSMetadataItemFSNameKey, "LSSharedFileList.plist")
            predicateToRun = NSCompoundPredicate(andPredicateWithSubpredicates: [predicateToRun, sflPredicate])
        }
        
        query?.predicate = predicateToRun
        query?.startQuery()
    }
    
    @objc func queryUpdated(notification: NSNotification) {
        query?.enumerateResultsUsingBlock(updateBlock)
    }
    
    func updateBlock(input: AnyObject!, index: Int, boolPoint: UnsafeMutablePointer<ObjCBool>) {
        let inputVal = input as! NSMetadataItem
        guard let path = inputVal.valueForKey(kMDItemPath as String),
                  date = inputVal.valueForKey(NSMetadataItemFSContentChangeDateKey as String),
                  newHistItem = fetchMostRecentDoc(fromFile: NSURL(fileURLWithPath: path as! String),
                  date: date as! NSDate)
                  else {
            return
        }
        if !allItems.contains(newHistItem) {
            for delegate in recentDocumentUpdateDelegates {
                delegate.newRecentDocument(newHistItem)
            }
            allItems.append(newHistItem)
        } else {
            let previousItemIndex = allItems.indexOf(newHistItem)!
            // Only re-add items if first time that it was opened was before kMinSeconds from now
            let shiftedDate = NSDate().dateByAddingTimeInterval(-kMinSeconds)
            let previousDate = allItems[previousItemIndex].lastAccessDate
            if shiftedDate.compare(previousDate) == NSComparisonResult.OrderedDescending {
                allItems[previousItemIndex].lastAccessDate = NSDate()
                for delegate in recentDocumentUpdateDelegates {
                    delegate.newRecentDocument(newHistItem)
                }
            }
        }
    }
    
    /// Extract the most recent opened document from the given shared file list
    ///
    /// - parameter fromFile: The path of the sfl file on disk
    /// - parameter date: The date on which the recend document was added
    /// - returns: A spotlight hist item representing the most recent opened document in the sfl
    private func fetchMostRecentDoc(fromFile filePath: NSURL, date: NSDate) -> RecentDocItem? {
        
        guard let sfl = NSDictionary(contentsOfURL: filePath), objects = sfl["$objects"] as? [AnyObject] else {
            return nil
        }
        
        // create tuples for each element in the sharedfilelist, first item is count, second path
        var tuples = [(count: Int, path: String)]()
        var i = 0
        while i < objects.count {
            // seek order (int) which comes before bookmark
            if let odict = objects[i] as? NSDictionary, order = odict["order"] {
                if let cnt = order as? Int {
                    
                    // seek bookmark and associate it to previously found order
                    while i < objects.count - 1 {
                        
                        i += 1
                        
                        if let possiblebook = objects[i] as? NSData, abookdict = NSURL.resourceValuesForKeys([NSURLPathKey], fromBookmarkData: possiblebook) {
                            
                            tuples.append((count: cnt, path: abookdict[NSURLPathKey]! as! String))
                            break
                        }
                    }
                }
            }
            i += 1
        }
        if tuples.count > 0 {
            // sort tuples by count in ascending order, take first item
            tuples = tuples.sort {$0.0 < $1.0}
            // most recent document URL
            let docUrl = NSURL(fileURLWithPath: tuples[0].path)
            // get application name by removing extension
            let docSource = filePath.URLByDeletingPathExtension!.lastPathComponent!
            let location = LocationSingleton.getCurrentLocation()
            return RecentDocItem(lastAccessDate: date, path: docUrl.path!, location: location, mime: docUrl.getMime()!, source: docSource)
        } else {
            return nil
        }
    }
}