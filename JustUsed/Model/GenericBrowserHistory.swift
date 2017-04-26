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
import CoreLocation

// MARK: - Types

/// Implementers of this protocol can receive updates regarding newer history items.
protocol BrowserHistoryUpdateDelegate {
    
    /// Notifies an update to history items. Passed a parameter is the new history item
    func newHistoryItems(_ newURLs: [BrowserHistItem])
}

/// A new safari history item will be returned as this to the delegate
struct BrowserHistItem: Equatable {
    let browser: BrowserType
    let date: Date
    let url: String
    let title: String?
    let location: Location?
    let excludedFromDiMe: Bool
    
    init(browser: BrowserType, date: Date, url: String, title: String?, location: Location?) {
        self.browser = browser
        self.date = date
        self.url = url
        self.title = title
        self.location = location
        
        // Set excluded property if url's domain is in exclude list
        if let url = URL(string: self.url), let domain = url.host {
            let excludeDomains = UserDefaults.standard.value(forKey: JustUsedConstants.prefExcludeDomains) as! [String]
            let filteredDomains = excludeDomains.filter({domain.range(of: $0) != nil})
            if filteredDomains.count > 0 {
                excludedFromDiMe = true
            } else {
                excludedFromDiMe = false
            }
        } else {
            excludedFromDiMe = false
        }
    }
}

func ==(lhs: BrowserHistItem, rhs: BrowserHistItem) -> Bool {
    return lhs.url == rhs.url && lhs.date.compare(rhs.date) == ComparisonResult.orderedSame && lhs.title == rhs.title
}

/// Each history fetcher should represent one of these browser types (e.g. SafariHistoryFetcher represents the BrowserType.Safari enum)
enum BrowserType: String {
    case Safari
    case Firefox
    case Chrome
}

// MARK: - Protocol specification

/// Implementers of this protocol provide new history items (e.g. url, visit time) for each browser
protocol BrowserHistoryFetcher: class {
    
    /// Must have a failable initializer that returns nil in case no database files exist (e.g. the user
    /// does not use the given browser)
    init?()
    
    /// The browser that this history fetcher represents. **best to implement this as let constant**
    var browserType: BrowserType { get }
    
    /// The last time an history item was retrieved. History items found in the db with a date newer than this
    /// are retrieved and this date is updated.
    var lastHistoryEntry: Date { get }
    
    /// The last time that the db files on disk were modified. If no change happened since this date, it is
    /// assumed no new history items exist.
    var lastDBFileUpdate: Date { get set }
    
    /// Returns paths for all valid database history files for this browser.
    /// **The first one should be the main database file** (e.g. .db file). If the returned list is empty,
    /// it is assumed the given browser is not being used.
    func getDBURLs() -> [URL]
    
    /// Returns all history items found in the database which have a date greater than the specified one.
    /// If the returned list is empty, no new items were found. **Called by extension**.
    /// Must close db files properly.
    func getNewHistoryItemsFromDB(_ dbPath: String) -> [BrowserHistItem]
}

extension BrowserHistoryFetcher {
    
    /// Returns the latest time that a database file was modified
    func latestDBTime() -> Date {
        var dates = [Date]()
        
        for fileUrl in getDBURLs() {
            
            var inVal: AnyObject?
            do {
                try (fileUrl as NSURL).getResourceValue(&inVal, forKey: URLResourceKey.contentModificationDateKey)
            } catch {
                AppSingleton.log.error("Something went wrong while reading db file '\(fileUrl.path)': \(error)")
            }
            if let fileDate = inVal as? Date {
                dates.append(fileDate)
            }
            
        }
        dates.sort(by: { $0.compare($1) == ComparisonResult.orderedDescending })
        return dates[0]
    }
    
    /// Copies all database files to temporary directory.
    /// Returns all paths, with the first one being the .db file (assuming getDBURLs() is implemented properly).
    /// Returns nil if the procedure fails.
    /// Files must be removed after this.
    func copyFiles() -> [String]? {
        let fileManager = AppSingleton.fileManager
        
        var allPaths = [String]()  // paths will be put here
        // Create temporary directory and delete previous temporary file (if present)
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("hiit.JustUsed")
        do {
            try fileManager.createDirectory(at: tempURL, withIntermediateDirectories: true, attributes: nil)
            //AppSingleton.log.debug("directory created succesfully")
        } catch {
            AppSingleton.log.error("Error while creating temp folder at \(tempURL.path): \(error)")
            return nil
        }
        
        // Copy files
        for dbPathURL in getDBURLs() {
            let filenameURL = dbPathURL
            let tempDataFileURL = tempURL.appendingPathComponent("\(browserType)_copied_\(filenameURL.lastPathComponent)")
            let tempDataFile = tempDataFileURL.path
            allPaths.append(tempDataFile)
            
            if fileManager.fileExists(atPath: tempDataFile) {
                //AppSingleton.log.debug("file exists already")
                do {
                    try fileManager.removeItem(at: tempDataFileURL)
                } catch {
                    AppSingleton.log.error("Error while removing temp file \(tempURL.path): \(error)")
                    return nil
                }
            }
            
            // Copy database
            if fileManager.fileExists(atPath: dbPathURL.path) {
                do {
                    try fileManager.copyItem(at: dbPathURL, to: tempDataFileURL)
                    //AppSingleton.log.debug("file created")
                } catch {
                    AppSingleton.log.error("Error while copying file \(dbPathURL.path): \(error)")
                }
            }
        }
        
        return allPaths
    }
    
    /// Performs database search and returns new items **preferred way to retrieve new items**.
    /// Returns new items, an empty list if there is nothing new.
    func historyCheck() -> [BrowserHistItem] {
        
        // We proceed only if the date database was modified is newer than the last date
        let dbTime = latestDBTime()
        if dbTime.compare(lastDBFileUpdate) == ComparisonResult.orderedDescending {
            lastDBFileUpdate = dbTime
        } else {
            // return empty list if nothing was updated
            return [BrowserHistItem]()
        }
        
        let tempPaths = copyFiles()  // copy files and get db file path
        
        if let paths = tempPaths {
            let tempDBpath = paths[0]
            let newItems = getNewHistoryItemsFromDB(tempDBpath)
            
            // Remove temporary files
            for filePath in paths {
                do {
                    try AppSingleton.fileManager.removeItem(atPath: filePath)
                    //AppSingleton.log.debug("succesfully removed")
                } catch {
                    AppSingleton.log.error("Something went wrong while removing old database \(filePath): \(error)")
                }
            }
            
            return newItems
        } else {
            return [BrowserHistItem]()
        }
    }
}

// MARK: - Manager

/// This class manages zero or more (depending on whether the user uses zero or more of the support browsers) BrowserHistoryFetchers (e.g. if the user uses only Safari
/// this class will manage one SafariHistoryFetcher instance).
/// The manager will retrieve history the way every specific BrowserHistoryFetcher defines at specific time intervals.
/// BrowserHistoryFetcher instances should add themselves to the browser history manager.
class BrowserHistoryManager: NSObject {
    
    /// Valid BrowserHistoryFetcher will be added to this array and repeatedly asked to retrieve new history items
    fileprivate var historyFetchers = [BrowserHistoryFetcher]()
    
    /// Update delegates which are interested in new history items (e.g. dime) are kept in this list.
    fileprivate var updateDelegates = [BrowserHistoryUpdateDelegate]()
    
    /// Checks for an update to the database file(s) every times this amount of seconds passes
    static let kCheckTimeInterval = 10.0
    
    /// Timer used for checking database file(s)
    fileprivate lazy var checkTimer: Timer = {
        return Timer(timeInterval: BrowserHistoryManager.kCheckTimeInterval, target: self, selector: #selector(timerFire(_:)), userInfo: nil, repeats: true)
    }()
    
    override init() {
        super.init()
        RunLoop.current.add(checkTimer, forMode: RunLoopMode.commonModes)
    }
    
    /// Adds support for a browser fetcher. Can pass initializer directly.
    func addFetcher(_ newFetcher: BrowserHistoryFetcher?) {
        if let fetcher = newFetcher {
            historyFetchers.append(fetcher)
        }
    }
    
    @objc func timerFire(_ timer: Timer) {
        var newItems = [BrowserHistItem]()
        for fetcher in historyFetchers {
            newItems.append(contentsOf: fetcher.historyCheck())
        }
        if newItems.count > 0 {
            for updateDelegate in updateDelegates {
                updateDelegate.newHistoryItems(newItems)
            }
        }
    }
    
    /// A delegate adds itself using this in order to receive updates regarding new history urls
    func addUpdateDelegate(_ updateDelegate: BrowserHistoryUpdateDelegate) {
        updateDelegates.append(updateDelegate)
    }
    
}
