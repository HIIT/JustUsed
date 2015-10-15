//
//  AppDelegate.swift
//  JustUsed
//
//  Created by Marco Filetti on 11/08/2015.
//  Copyright (c) 2015 HIIT. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // View controller that will be displayed after pressing menubaar button
    var viewController: ViewController?
    
    // Trackers
    let safHistoryFetcher = SafariHistoryFetcher()
    let spoTracker = SpotlightTracker()
    
    // Data sources to display tables in GUI
    let safHistoryDataSource = SafariTrackerDataSource()
    let spoHistoryDataSource = SpotlightTrackerDataSource()
    
    /// Popover that will be displayed while clicking on menubar button
    let popover = NSPopover() 
    
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSSquareStatusItemLength)

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        // Set default preferences
        var defaultPrefs = [String: AnyObject]()
        defaultPrefs[JustUsedConstants.prefDiMeServerURL] = "http://localhost:8080/api"
        defaultPrefs[JustUsedConstants.prefDiMeServerUserName] = "Test1"
        defaultPrefs[JustUsedConstants.prefDiMeServerPassword] = "123456"
        defaultPrefs[JustUsedConstants.prefSendPlainTexts] = 1
        defaultPrefs[JustUsedConstants.prefSendSafariHistory] = 1
        NSUserDefaults.standardUserDefaults().registerDefaults(defaultPrefs)
        NSUserDefaults.standardUserDefaults().synchronize()
        
        // Starts dime
        HistoryManager.sharedManager.dimeConnect()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "diMeConnectionChanged:", name: JustUsedConstants.diMeConnectionNotification, object: HistoryManager.sharedManager)
        
        if let _ = LocationSingleton.getCurrentLocation() {
            // just fetch nothing to initialise location
        }
        if let button = statusItem.button {
            button.image = NSImage(named: JustUsedConstants.kMenuImageName)
            button.action = Selector("togglePopover:")
        }
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        popover.behavior = NSPopoverBehavior.Transient
        
        // View controller and its delegation
        self.viewController = (storyboard.instantiateControllerWithIdentifier("View Controller") as! ViewController)
        viewController!.setSources(spoHistoryDataSource, safariSource: safHistoryDataSource)
        popover.contentViewController = self.viewController!
        safHistoryFetcher.addUpdateDelegate(self.viewController!)
        spoTracker.addSpotlightDataDelegate(self.viewController!)
        
        // History manager and its delegation
        safHistoryFetcher.addUpdateDelegate(HistoryManager.sharedManager)
        spoTracker.addSpotlightDataDelegate(HistoryManager.sharedManager)
        
        diMeConnectionChanged(nil)
    }
    
    /// Updates itself when connection is lost / resumed
    @objc private func diMeConnectionChanged(notification: NSNotification?) {
        statusItem.button!.appearsDisabled = !HistoryManager.sharedManager.isDiMeAvailable()
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: JustUsedConstants.diMeConnectionNotification, object: HistoryManager.sharedManager)
    }

    func showPopover(sender: AnyObject?) {
        if let button = statusItem.button {
            popover.showRelativeToRect(button.bounds, ofView: button, preferredEdge: NSRectEdge.MinY)
        }
    }
    
    func closePopover(sender: AnyObject?) {
        popover.performClose(sender)
    }
    
    func togglePopover(sender: AnyObject?) {
        if popover.shown {
            closePopover(sender)
        } else {
            showPopover(sender)
        }
    }
    
    func quit() {
        // TODO: close open files, etc before terminating
        NSApp.terminate(self)
    }
}
