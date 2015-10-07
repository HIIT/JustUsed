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
    
    let popover = NSPopover() 
    
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSSquareStatusItemLength)

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        if let button = statusItem.button {
            button.image = NSImage(named: "DiMeTemplate")
            button.action = Selector("togglePopover:")
        }
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        popover.contentViewController = storyboard.instantiateControllerWithIdentifier("View Controller") as! ViewController
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

