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

/// Tracks recent documents by looking at *LSSharedFileList.plist files found in ~Library/Preferences, which is the method
/// used by Yosemite to save recently opened documents
class RecentPlistTracker: RecentDocumentsTracker {
    
    /// Convenience file manager
    fileprivate var fm = FileManager.default
    
    /// Plists' last modification date is stored in this dictionary
    fileprivate var allPlists = [URL: Date]()
    
    /// Files are tracked every this amount of seconds
    fileprivate let kPlistCheckTime = 5.0
    
    required init() {
        super.init()
        
        // Initialise allPlists by looking at all files in the Library/Preferences directory
        for tuple in getAllPlists() {
            allPlists[tuple.sflUrl] = tuple.modDate
        }
        
        // Start timer
        let checkTimer = Timer(timeInterval: kPlistCheckTime, target: self, selector: #selector(timerHit(_:)), userInfo: nil, repeats: true)
        RunLoop.current.add(checkTimer, forMode: RunLoopMode.commonModes)
    }
    
    /// Check if any recent document plist has been modified since last time the timer hit
    @objc fileprivate func timerHit(_ theTimer: Timer) {
        for tuple in getAllPlists() {
            
            // if previous item exists, check date, otherwise add it
            if let previousModDate = allPlists[tuple.sflUrl] {
                // check if the just found modification date is more recent than the last found one
                if tuple.modDate.compare(previousModDate) == ComparisonResult.orderedDescending {
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
    fileprivate func fetchMostRecentDoc(fromFile filePath: URL, date: Date) -> RecentDocItem? {
        
        guard let sfl = NSDictionary(contentsOf: filePath),
                  let recents = sfl["RecentDocuments"] as? [String: Any],
                  let objects = recents["CustomListItems"] as? [[String: Any]],
                  let mostrecentpossiblebook = objects[0]["Bookmark"] as? Data,
                  let abookdict = URL.resourceValues(forKeys: [URLResourceKey.pathKey], fromBookmarkData: mostrecentpossiblebook)
                  else {
            return nil
        }
        guard let path = abookdict.path else {
            AppSingleton.log.error("Failed to find path from file: \(filePath.path)")
            return nil
        }
        let docUrl = URL(fileURLWithPath: path)
        let rangeOfLSSharedFileList = filePath.lastPathComponent.range(of: ".LSSharedFileList")
        let docSource = filePath.lastPathComponent.substring(to: rangeOfLSSharedFileList!.lowerBound)
        let location = LocationSingleton.getCurrentLocation()
        return RecentDocItem(lastAccessDate: date, path: docUrl.path, location: location, mime: docUrl.getMime()!, source: docSource)
    }
    
    
    /// Returns all plist files related to recents documents and their last modification date in a tuple
    fileprivate func getAllPlists() -> [(sflUrl: URL, modDate: Date)] {
        var retVal = [(sflUrl: URL, modDate: Date)]()
        
        let preferencesDir = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Preferences")
        do {
            let allPrefs = try fm.contentsOfDirectory(at: preferencesDir, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions())
            let sfls = allPrefs.filter({$0.lastPathComponent.range(of: "LSSharedFileList.plist") != nil})
            
            for sfl in sfls {
                var inVal: AnyObject?
                do {
                    try (sfl as NSURL).getResourceValue(&inVal, forKey: URLResourceKey.contentModificationDateKey)
                    if let fileDate = inVal as? Date {
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
