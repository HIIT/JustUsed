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
    }

    func applicationWillTerminate(aNotification: NSNotification) {
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

