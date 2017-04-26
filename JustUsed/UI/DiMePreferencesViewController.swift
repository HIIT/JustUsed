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
        calendarExcludeTable.dataSource = calendarExcludeDelegate
        calendarExcludeTable.delegate = calendarExcludeDelegate
        
        let options: [String: AnyObject] = ["NSContinuouslyUpdatesValue": true as AnyObject]
        
        urlField.bind("value", to: NSUserDefaultsController.shared(), withKeyPath: "values." + JustUsedConstants.prefDiMeServerURL, options: options)
        
        usernameField.bind("value", to: NSUserDefaultsController.shared(), withKeyPath: "values." + JustUsedConstants.prefDiMeServerUserName, options: options)
        
        passwordField.bind("value", to: NSUserDefaultsController.shared(), withKeyPath: "values." + JustUsedConstants.prefDiMeServerPassword, options: options)
        
        // the following will set
        // (PeyeConstants.prefSendEventOnFocusSwitch)
        // to optional int 0 when off and nonzero (1) when on
        sendPlainTextCell.bind("value", to: NSUserDefaultsController.shared(), withKeyPath: "values." + JustUsedConstants.prefSendPlainTexts, options: options)
        
        // similar set here
        // Browser history disabled in favour of extension
        // sendSafariHistCell.bind("value", toObject: NSUserDefaultsController.sharedUserDefaultsController(), withKeyPath: "values." + JustUsedConstants.prefSendSafariHistory, options: options)
        
        logsPathLabel.stringValue = AppSingleton.logsURL?.path ?? "<Nothing logged so far>"
        
    }
    
    /// Domain names
    @IBOutlet weak var userDefaultsAC: NSArrayController!
    @IBOutlet weak var domainsTable: NSTableView!
    @IBOutlet weak var newDomainField: NSTextField!
    
    @IBAction func removeButtonPress(_ sender: NSButton) {
        if domainsTable.selectedRow != -1 {
            userDefaultsAC.remove(atArrangedObjectIndex: domainsTable.selectedRow)
        }
    }
    
    @IBAction func addButtonPress(_ sender: NSButton) {
        let newVal = newDomainField.stringValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if newVal.characters.count > 0 {
            let cont = userDefaultsAC.content as! [String]
            if cont.index(of: newVal) == nil {
                userDefaultsAC.addObject(newVal)
            }
            newDomainField.stringValue = ""
        }
    }
    
    @IBAction func calendarDataMine(_ sender: NSButton) {
        let myAl = NSAlert()
        myAl.messageText = "Attention: this will fetch ALL events, ± 2 years from now (unless they belong to an excluded calendar). Are you sure?"
        myAl.addButton(withTitle: "Yes")
        myAl.addButton(withTitle: "No")
        myAl.beginSheetModal(for: self.view.window!, completionHandler: {
            response in
            
            if response == NSAlertFirstButtonReturn {
                DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
                    let appDel = NSApplication.shared().delegate! as! AppDelegate
                    appDel.calendarTracker.submitEvents(dataMine: true)
                }
            }
            
        }) 
    }
    
}

class CalendarExcludeDelegate: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    let calendarTracker: CalendarTracker = {
        let appDel = NSApplication.shared().delegate! as! AppDelegate
        return appDel.calendarTracker
    }()
    
    @objc func numberOfRows(in tableView: NSTableView) -> Int {
        return calendarTracker.calendarNames()!.count
    }
    
    @objc func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if tableColumn!.identifier == "calExclTableCheck" {
            let cal = calendarTracker.calendarNames()![row]
            return calendarTracker.getExcludeCalendars()![cal]
        } else {
            return calendarTracker.calendarNames()![row]
        }
    }
    
    @objc func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        if tableColumn!.identifier == "calExclTableCheck" {
            let exclude = object! as! Bool
            _ = calendarTracker.setExcludeValue(exclude: exclude, calendar: calendarTracker.calendarNames()![row])
            tableView.reloadData()
        }
    }
}
