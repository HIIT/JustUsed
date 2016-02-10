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

class DiMePreferencesViewController: NSViewController {
    
    @IBOutlet weak var urlField: NSTextField!
    @IBOutlet weak var usernameField: NSTextField!
    @IBOutlet weak var passwordField: NSTextField!
    @IBOutlet weak var sendPlainTextCell: NSButtonCell!
    @IBOutlet weak var sendSafariHistCell: NSButtonCell!
    
    @IBOutlet weak var logsPathLabel: NSTextField!
    
    @IBOutlet weak var calendarExcludeTable: NSTableView!
    let calendarExcludeDelegate = CalendarExcludeDelegate()
    
    /// Create view and programmatically set-up bindings
    override func viewDidLoad() {
        super.viewDidLoad()
        calendarExcludeTable.setDataSource(calendarExcludeDelegate)
        calendarExcludeTable.setDelegate(calendarExcludeDelegate)
        
        let options: [String: AnyObject] = ["NSContinuouslyUpdatesValue": true]
        
        urlField.bind("value", toObject: NSUserDefaultsController.sharedUserDefaultsController(), withKeyPath: "values." + JustUsedConstants.prefDiMeServerURL, options: options)
        
        usernameField.bind("value", toObject: NSUserDefaultsController.sharedUserDefaultsController(), withKeyPath: "values." + JustUsedConstants.prefDiMeServerUserName, options: options)
        
        passwordField.bind("value", toObject: NSUserDefaultsController.sharedUserDefaultsController(), withKeyPath: "values." + JustUsedConstants.prefDiMeServerPassword, options: options)
        
        // the following will set
        // (PeyeConstants.prefSendEventOnFocusSwitch)
        // to optional int 0 when off and nonzero (1) when on
        sendPlainTextCell.bind("value", toObject: NSUserDefaultsController.sharedUserDefaultsController(), withKeyPath: "values." + JustUsedConstants.prefSendPlainTexts, options: options)
        
        // similar set here
        sendSafariHistCell.bind("value", toObject: NSUserDefaultsController.sharedUserDefaultsController(), withKeyPath: "values." + JustUsedConstants.prefSendSafariHistory, options: options)
        
        logsPathLabel.stringValue = AppSingleton.logsURL.path ?? "<Nothing logged so far>"
        
    }
    
    /// Domain names
    @IBOutlet weak var userDefaultsAC: NSArrayController!
    @IBOutlet weak var domainsTable: NSTableView!
    @IBOutlet weak var newDomainField: NSTextField!
    
    @IBAction func removeButtonPress(sender: NSButton) {
        if domainsTable.selectedRow != -1 {
            userDefaultsAC.removeObjectAtArrangedObjectIndex(domainsTable.selectedRow)
        }
    }
    
    @IBAction func addButtonPress(sender: NSButton) {
        let newVal = newDomainField.stringValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        if newVal.characters.count > 0 {
            let cont = userDefaultsAC.content as! [String]
            if cont.indexOf(newVal) == nil {
                userDefaultsAC.addObject(newVal)
            }
            newDomainField.stringValue = ""
        }
    }
    
    @IBAction func calendarDataMine(sender: NSButton) {
        let myAl = NSAlert()
        myAl.messageText = "Attention: this will fetch ALL events, ± 2 years from now (unless they belong to an excluded calendar). Are you sure?"
        myAl.addButtonWithTitle("Yes")
        myAl.addButtonWithTitle("No")
        myAl.beginSheetModalForWindow(self.view.window!) {
            response in
            
            if response == NSAlertFirstButtonReturn {
                dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
                    let appDel = NSApplication.sharedApplication().delegate! as! AppDelegate
                    appDel.calendarTracker.submitEvents(dataMine: true)
                }
            }
            
        }
    }
    
}

class CalendarExcludeDelegate: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    let calendarTracker: CalendarTracker = {
        let appDel = NSApplication.sharedApplication().delegate! as! AppDelegate
        return appDel.calendarTracker
    }()
    
    @objc func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return calendarTracker.calendarNames()!.count
    }
    
    @objc func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        if tableColumn!.identifier == "calExclTableCheck" {
            let cal = calendarTracker.calendarNames()![row]
            return calendarTracker.getExcludeCalendars()![cal]
        } else {
            return calendarTracker.calendarNames()![row]
        }
    }
    
    @objc func tableView(tableView: NSTableView, setObjectValue object: AnyObject?, forTableColumn tableColumn: NSTableColumn?, row: Int) {
        if tableColumn!.identifier == "calExclTableCheck" {
            let exclude = object! as! Bool
            calendarTracker.setExcludeValue(exclude: exclude, calendar: calendarTracker.calendarNames()![row])
            tableView.reloadData()
        }
    }
}
