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

import Cocoa

class ViewController: NSViewController, RecentDocumentUpdateDelegate, BrowserHistoryUpdateDelegate {
    
    // Whether the button says connect or disconnect (to avoid using strings)
    let kTagConnect: Int = 1
    let kTagDisconnect: Int = 2
    
    // File table width when both tables are shown
    let fileTableWidthForBoth: CGFloat = 477
    
    weak var spotlightSource: RecentDocDataSource?
    weak var browserSource: BrowserTrackerDataSource?
    
    @IBOutlet weak var browserTable: NSTableView!
    @IBOutlet weak var fileTable: NSTableView!
    
    // DiMe statuses
    @IBOutlet weak var statusButton: NSButton!
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var statusImage: NSImageView!
    
    @IBOutlet weak var fileTableWidth: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear() {
        if (UserDefaults.standard.value(forKey: JustUsedConstants.prefSendSafariHistory) as! Bool) {
            fileTableWidth.constant = fileTableWidthForBoth
        } else {
            fileTableWidth.constant = self.view.bounds.width - 40
        }
    }
    
    override func viewDidAppear() {
        NotificationCenter.default.addObserver(self, selector: #selector(dimeConnectionChanged(_:)), name: JustUsedConstants.diMeConnectionNotification, object: HistoryManager.sharedManager)
        updateDiMeStatus()
        
        fileTable.dataSource = spotlightSource
        browserTable.dataSource = browserSource
    }
    
    override func viewDidDisappear() {
        NotificationCenter.default.removeObserver(self, name: JustUsedConstants.diMeConnectionNotification, object: HistoryManager.sharedManager)
    }
    
    /// Must call this function to set-up delegates and data sources
    func setSources(_ spotlightSource: RecentDocDataSource, browserSource: BrowserTrackerDataSource) {
        self.spotlightSource = spotlightSource
        self.browserSource = browserSource
    }
    
    func newRecentDocument(_ newItem: RecentDocItem) {
        spotlightSource!.addData(newItem)
        fileTable?.reloadData()
    }
    
    func newHistoryItems(_ newURLs: [BrowserHistItem]) {
        browserSource!.insertNewData(newURLs)
        browserTable?.reloadData()
    }
    
    /// Checks dime status and updates view accordingly
    fileprivate func updateDiMeStatus() {
        if DiMeSession.dimeAvailable {
            statusImage.image = NSImage(named: NSImage.Name(rawValue: "NSStatusAvailable"))
            statusButton.tag = kTagDisconnect
            statusButton.title = "Disconnect"
            statusLabel.stringValue = "Connected"
        } else {
            statusLabel.stringValue = "Disconnected"
            statusImage.image = NSImage(named: NSImage.Name(rawValue: "NSStatusUnavailable"))
            statusButton.tag = kTagConnect
            statusButton.title = "Connect"
        }
    }
    
    @IBAction func connectButtonPress(_ sender: NSButton) {
        if sender.tag == kTagDisconnect {
            HistoryManager.forceDisconnect = true
            DiMeSession.dimeDisconnect()
        } else if sender.tag == kTagConnect {
            HistoryManager.forceDisconnect = false
            DiMeSession.dimeConnect()
        }
    }
    
    @objc fileprivate func dimeConnectionChanged(_ notification: Notification) {
        updateDiMeStatus()
    }
    
    @IBAction func quitButtonPress(_ sender: NSButton) {
        let delegate = NSApplication.shared.delegate! as! AppDelegate
        delegate.quit()
    }
}

class BrowserTrackerDataSource: NSObject, NSTableViewDataSource  {
    
    var allHistory = [BrowserHistItem]()
    
    // Insert data avoiding duplicates
    func insertNewData(_ newURLs: [BrowserHistItem]) {
        for newUrl in newURLs {
            if !allHistory.contains(newUrl) {
                allHistory.append(newUrl)
            }
        }
    }
    
    /// MARK: - Table data source
    func numberOfRows(in aTableView: NSTableView) -> Int {
        return allHistory.count
    }
    
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if tableColumn!.identifier.rawValue == JustUsedConstants.kBHistoryDate {
            let date = allHistory[row].date
            return date.description(with: Locale.current)
        } else if tableColumn!.identifier.rawValue == JustUsedConstants.kBHistoryBrowser {
            return allHistory[row].browser.rawValue
        } else if tableColumn!.identifier.rawValue == JustUsedConstants.kBHistoryTitle {
            if let title = allHistory[row].title {
                return title
            } else {
                return ""
            }
        } else if tableColumn!.identifier.rawValue == JustUsedConstants.kLocTitle {
            if let locString = allHistory[row].location?.descriptionLine {
                return locString
            } else {
                return JustUsedConstants.kUnkownLocationString
            }
        } else if tableColumn!.identifier.rawValue == JustUsedConstants.kBHistoryExcluded {
            return allHistory[row].excludedFromDiMe ? "Yes" : "No"
        } else {
            return allHistory[row].url
        }
    }
    
}

class RecentDocDataSource: NSObject, NSTableViewDataSource {
    
    var lutimes = [String]()
    var lupaths = [String]()
    var sources = [String]()
    var locations = [String]()
    var mimes = [String]()
    
    func addData(_ newItem: RecentDocItem) {
        lutimes.append(newItem.lastAccessDate.description(with: Locale.current))
        lupaths.append(newItem.path)
        sources.append(newItem.source)
        if let locString = newItem.location?.descriptionLine {
            locations.append(locString)
        } else {
            locations.append(JustUsedConstants.kUnkownLocationString)
        }
        mimes.append(newItem.mime)
    }
    
    
    /// MARK: Static table data source
    func numberOfRows(in aTableView: NSTableView) -> Int {
        return lutimes.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if tableColumn!.identifier.rawValue == JustUsedConstants.kLastUsedDateTitle {
            return lutimes[row]
        } else if tableColumn!.identifier.rawValue == JustUsedConstants.kPathTitle {
            return lupaths[row]
        } else if tableColumn!.identifier.rawValue == JustUsedConstants.kSourceTitle {
            return sources[row]
        } else if tableColumn!.identifier.rawValue == JustUsedConstants.kLocTitle {
            return locations[row]
        } else if tableColumn!.identifier.rawValue == JustUsedConstants.kMimeType {
            return mimes[row]
        } else {
            return nil
        }
    }

}
