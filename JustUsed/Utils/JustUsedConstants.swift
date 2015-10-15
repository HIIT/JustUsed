//
//  JustUsedConstants.swift
//  JustUsed
//
//  Created by Marco Filetti on 13/08/2015.
//  Copyright (c) 2015 HIIT. All rights reserved.
//

import Foundation

class JustUsedConstants {
    // MARK: - Tables
    // Make sure these constants match the column identifiers (also titles)
    static let kLastUsedDateTitle = "Last Used Date"
    static let kPathTitle = "File Path"
    static let kIndexTitle = "Index Int"
    static let kBoolPointTitle = "f_Stopped"
    static let kMimeType = "Mime type"
    static let kLocTitle = "Location description"
    static let kSHistoryDate = "URL Visit time"
    static let kSHistoryURL = "Visited URL"
    static let kSHistoryTitle = "Page title"
    static let kMenuImageName = "DiMeTemplate"
    
    // MARK: - Preference identifiers
    
    /// URL of the DiMe server (bound in the preferences window)
    static let prefDiMeServerURL = "dime.serverinfo.url"
    
    /// Username of the DiMe server (bound in the preferences window)
    static let prefDiMeServerUserName = "dime.serverinfo.userName"
    
    /// Password of the DiMe server (bound in the preferences window)
    static let prefDiMeServerPassword = "dime.serverinfo.password"
    
    /// Wheter we want to push an event at every window focus event (bound in the preferences window)
    static let prefSendPlainTexts = "dime.preferences.sendPlainTexts"
    
    /// Wheter we send Safari history events to DiMe
    static let prefSendSafariHistory = "dime.preferences.sendSafariHistory"
    
    // MARK: - Notifications
    
    /// String notifying that something changed in the dime connection.
    /// Calls to HistoryManager can verify what is the current status of dime
    /// using isDimeAvailable().
    static let diMeConnectionNotification = "hiit.JustUsed.diMeConnectionChange"
    
    // MARK: - General constants
    
    // Minumum amount of seconds needed to re-adding a spotlight item to history (to prevent many duplicates)
    static let kSpotlightMinSeconds = 300.0
    
    /// Date formatter shared in DiMe submissions (uses date format below)
    static let diMeDateFormatter = JustUsedConstants.makeDateFormatter()
    
    /// Date format used for DiMe submission
    static let diMeDateFormat = "Y'-'MM'-'d'T'HH':'mm':'ssZ"
    
    // MARK: - Static functions
    
    private static func makeDateFormatter() -> NSDateFormatter {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = JustUsedConstants.diMeDateFormat
        return dateFormatter
    }
    
}
    