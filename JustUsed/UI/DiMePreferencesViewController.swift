//
//  PreferencesWindowController.swift
//  PeyeDF
//
//  Created by Marco Filetti on 25/08/2015.
//  Copyright (c) 2015 HIIT. All rights reserved.
//

import Foundation
import Cocoa

class DiMePreferencesViewController: NSViewController {
    
    @IBOutlet weak var urlField: NSTextField!
    @IBOutlet weak var usernameField: NSTextField!
    @IBOutlet weak var passwordField: NSTextField!
    @IBOutlet weak var sendPlainTextCell: NSButtonCell!
    @IBOutlet weak var sendSafariHistCell: NSButtonCell!
    
    @IBOutlet weak var logsPathLabel: NSTextField!
    
    /// Create view and programmatically set-up bindings
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        logsPathLabel.stringValue = AppSingleton.logsURL.path ?? "<nil>"
        
    }
}
