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

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // View controller that will be displayed after pressing menubar button
    var viewController: ViewController?
    
    // Trackers
    
    // Browser history tracking disabled in favour of extension
    // let browserManager = BrowserHistoryManager()
    
    let recentDocTracker: RecentDocumentsTracker = {
        if AppSingleton.aboveYosemite {
            return SpotlightDocumentTracker()
        } else {
            return RecentPlistTracker()
        }
    }()
    
    let calendarTracker = CalendarTracker()
    
    // Data sources to display tables in GUI
    let browHistoryDataSource = BrowserTrackerDataSource()
    let spoHistoryDataSource = RecentDocDataSource()
    
    /// Popover that will be displayed while clicking on menubar button
    let popover = NSPopover() 
    
    let statusItem = NSStatusBar.system().statusItem(withLength: NSSquareStatusItemLength)

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        // Set default preferences
        var defaultPrefs = [String: AnyObject]()
        defaultPrefs[JustUsedConstants.prefDiMeServerURL] = "http://localhost:8080/api" as AnyObject
        defaultPrefs[JustUsedConstants.prefDiMeServerUserName] = "Test1" as AnyObject
        defaultPrefs[JustUsedConstants.prefDiMeServerPassword] = "123456" as AnyObject
        let defaultExcludeDomains = ["localhost", "talkgadget.google.com"]
        let defaultExcludeCalendars: [String] = []
        defaultPrefs[JustUsedConstants.prefExcludeCalendars] = defaultExcludeCalendars as AnyObject
        defaultPrefs[JustUsedConstants.prefExcludeDomains] = defaultExcludeDomains as AnyObject
        defaultPrefs[JustUsedConstants.prefSendPlainTexts] = 1 as AnyObject
        defaultPrefs[JustUsedConstants.prefSendSafariHistory] = 0 as AnyObject
        UserDefaults.standard.register(defaults: defaultPrefs)
        UserDefaults.standard.synchronize()
        
        // Starts dime
        NotificationCenter.default.addObserver(self, selector: #selector(diMeConnectionChanged(_:)), name: JustUsedConstants.diMeConnectionNotification, object: nil)
        
        DiMeSession.dimeConnect()
        if let _ = LocationSingleton.getCurrentLocation() {
            // just fetch nothing to initialise location
        }
        if let button = statusItem.button {
            button.image = NSImage(named: JustUsedConstants.kMenuImageName)
            button.action = #selector(togglePopover(_:))
        }
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        popover.behavior = NSPopoverBehavior.transient
        
        // View controller and its delegation
        self.viewController = (storyboard.instantiateController(withIdentifier: "View Controller") as! ViewController)
        viewController!.setSources(spoHistoryDataSource, browserSource: browHistoryDataSource)
        popover.contentViewController = self.viewController!
        recentDocTracker.addRecentDocumentUpdateDelegate(self.viewController!)
        
        // History manager and its delegation
        recentDocTracker.addRecentDocumentUpdateDelegate(HistoryManager.sharedManager)
        
        // Browser history tracking (disabled in favour of extension)
        /*
        browserManager.addFetcher(SafariHistoryFetcher())
        browserManager.addFetcher(FirefoxHistoryFetcher())
        browserManager.addFetcher(ChromeHistoryFetcher())
        browserManager.addUpdateDelegate(self.viewController!)
        browserManager.addUpdateDelegate(HistoryManager.sharedManager)
        */
        
        diMeConnectionChanged(nil)
        
    }
    
    /// Updates itself when connection is lost / resumed
    @objc fileprivate func diMeConnectionChanged(_ notification: Notification?) {
        statusItem.button!.appearsDisabled = !DiMeSession.dimeAvailable
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        NotificationCenter.default.removeObserver(self, name: JustUsedConstants.diMeConnectionNotification, object: HistoryManager.sharedManager)
    }

    func showPopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }
    
    func closePopover(_ sender: AnyObject?) {
        popover.performClose(sender)
    }
    
    func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
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

