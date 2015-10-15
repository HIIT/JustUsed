//
//  ViewController.swift
//  JustUsed
//
//  Created by Marco Filetti on 11/08/2015.
//  Copyright (c) 2015 HIIT. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, SpotlightHistoryUpdateDelegate, SafariHistoryUpdateDelegate {
    
    // Whether the button says connect or disconnect (to avoid using strings)
    let kTagConnect: Int = 1
    let kTagDisconnect: Int = 2
    
    weak var spotlightSource: SpotlightTrackerDataSource?
    weak var safariSource: SafariTrackerDataSource?
    
    @IBOutlet weak var safariTable: NSTableView!
    @IBOutlet weak var fileTable: NSTableView!
    
    // DiMe statuses
    @IBOutlet weak var statusButton: NSButton!
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var statusImage: NSImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dimeConnectionChanged:", name: JustUsedConstants.diMeConnectionNotification, object: HistoryManager.sharedManager)
        updateDiMeStatus()
        
        fileTable.setDataSource(spotlightSource)
        safariTable.setDataSource(safariSource)
    }
    
    override func viewDidDisappear() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: JustUsedConstants.diMeConnectionNotification, object: HistoryManager.sharedManager)
    }
    
    /// Must call this function to set-up delegates and data sources
    func setSources(spotlightSource: SpotlightTrackerDataSource, safariSource: SafariTrackerDataSource) {
        self.spotlightSource = spotlightSource
        self.safariSource = safariSource
    }
    
    func newSpotlightData(newItem: SpotlightHistItem) {
        spotlightSource!.addData(newItem)
        fileTable?.reloadData()
    }
    
    func newHistoryItems(newURLs: [SafariHistItem]) {
        safariSource!.insertNewData(newURLs)
        safariTable?.reloadData()
    }
    
    /// Checks dime status and updates view accordingly
    private func updateDiMeStatus() {
        if HistoryManager.sharedManager.isDiMeAvailable() {
            statusImage.image = NSImage(named: "NSStatusAvailable")
            statusButton.tag = kTagDisconnect
            statusButton.title = "Disconnect"
            statusLabel.stringValue = "Connected"
        } else {
            statusLabel.stringValue = "Disconnected"
            statusImage.image = NSImage(named: "NSStatusUnavailable")
            statusButton.tag = kTagConnect
            statusButton.title = "Connect"
        }
    }
    
    @IBAction func connectButtonPress(sender: NSButton) {
        if sender.tag == kTagDisconnect {
            HistoryManager.sharedManager.dimeDisconnect()
        } else if sender.tag == kTagConnect {
            HistoryManager.sharedManager.dimeConnect()
        }
    }
    
    @objc private func dimeConnectionChanged(notification: NSNotification) {
        updateDiMeStatus()
    }
    
    @IBAction func quitButtonPress(sender: NSButton) {
        let delegate = NSApplication.sharedApplication().delegate! as! AppDelegate
        delegate.quit()
    }
}

class SafariTrackerDataSource: NSObject, NSTableViewDataSource  {
    
    var allHistory = [SafariHistItem]()
    
    // Insert data avoiding duplicates
    func insertNewData(newURLs: [SafariHistItem]) {
        for newUrl in newURLs {
            if !allHistory.contains(newUrl) {
                allHistory.append(newUrl)
            }
        }
    }
    
    /// MARK: - Table data source
    func numberOfRowsInTableView(aTableView: NSTableView) -> Int {
        return allHistory.count
    }
    
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        if tableColumn!.identifier == JustUsedConstants.kSHistoryDate {
            let date = allHistory[row].date
            return date.descriptionWithLocale(NSLocale.currentLocale())
        } else if tableColumn!.identifier == JustUsedConstants.kSHistoryTitle {
            if let title = allHistory[row].title {
                return title
            } else {
                return ""
            }
        } else if tableColumn!.identifier == JustUsedConstants.kLocTitle {
            if let location = allHistory[row].location {
                return location.locationString
            } else {
                return MyLocation.kUnknownLocation.locationString
            }
        } else {
            return allHistory[row].url
        }
    }
    
}

class SpotlightTrackerDataSource: NSObject, NSTableViewDataSource {
    
    var lutimes = [String]()
    var lupaths = [String]()
    var integers = [String]()
    var locations = [String]()
    var mimes = [String]()
    
    func addData(newItem: SpotlightHistItem) {
        lutimes.append(newItem.lastAccessDate.descriptionWithLocale(NSLocale.currentLocale()))
        lupaths.append(newItem.path)
        integers.append("\(newItem.index)")
        if let location = newItem.location {
            locations.append(location.locationString)
        } else {
            locations.append(MyLocation.kUnknownLocation.locationString)
        }
        mimes.append(newItem.mime)
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
            return nil
        }
    }

}