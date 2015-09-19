//
//  ViewController.swift
//  JustUsed
//
//  Created by Marco Filetti on 11/08/2015.
//  Copyright (c) 2015 HIIT. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, SpotlightTrackerDelegate, SafariHistoryUpdateDelegate {
    
    @IBOutlet weak var safariTable: NSTableView!
    @IBOutlet weak var fileTable: NSTableView!
    
    var historyFetcher = SafariHistoryFetcher()
    var historyDataSource = SafariTrackerDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        fileTable.setDataSource(SpotlightTrackerSingleton.getFileTracker())
        SpotlightTrackerSingleton.getFileTracker().setDelegate(self)
        
        safariTable.setDataSource(historyDataSource)
        historyFetcher.setUpdateDelegate(self)
    }
    
    func newSpotlightData() {
        fileTable.reloadData()
    }
    
    func newHistoryItems(newURLs: [HistItem]) {
        historyDataSource.insterNewData(newURLs)
        safariTable.reloadData()
    }
}

class SafariTrackerDataSource: NSObject, NSTableViewDataSource {
    
    var allHistory = [HistItem]()
    
    override init() {
        super.init()
    }
    
    // Insert data avoiding duplicates
    func insterNewData(newURLs: [HistItem]) {
        for newUrl in newURLs {
            if !allHistory.contains(newUrl) {
                allHistory.append(newUrl)
            }
        }
    }
    
    /// MARK: Table data source
    func numberOfRowsInTableView(aTableView: NSTableView) -> Int {
        return allHistory.count
    }
    
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        if tableColumn!.identifier == JustUsedConstants.kSHistoryDate {
            let date = allHistory[row].date
            return date.descriptionWithLocale(NSLocale.currentLocale())
        } else if tableColumn!.identifier == JustUsedConstants.kSHistoryTitle {
            return allHistory[row].title
        } else if tableColumn!.identifier == JustUsedConstants.kLocTitle {
            return LocationSingleton.getLocationString()
        } else {
            return allHistory[row].url
        }
    }
    
}

