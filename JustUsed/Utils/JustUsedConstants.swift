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

class JustUsedConstants {
    // MARK: - Tables
    // Make sure these constants match the column identifiers (also titles)
    static let kLastUsedDateTitle = "Last Used Date"
    static let kPathTitle = "File Path"
    static let kSourceTitle = "Source"
    static let kBoolPointTitle = "f_Stopped"
    static let kMimeType = "Mime type"
    static let kLocTitle = "Location description"
    static let kBHistoryBrowser = "Browser"
    static let kBHistoryExcluded = "Excluded"
    static let kBHistoryDate = "URL Visit time"
    static let kBHistoryURL = "Visited URL"
    static let kBHistoryTitle = "Page title"
    static let kMenuImageName = "DiMeTemplate"
    
    // MARK: - Preference identifiers
    
    /// Preference index representing list of excluded domains.
    /// - Note: changing this requires manual change in the preferences' array controller
    static let prefExcludeDomains = "pref.excludeDomains"
    
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
    
    /// String list of calendars we want to exclude from monitoring
    static let prefExcludeCalendars = "dime.preferences.excludeCalendars"
    
    // MARK: - Notifications
    
    /// String notifying that something changed in the dime connection.
    /// Calls to HistoryManager can verify what is the current status of dime
    /// using isDimeAvailable().
    static let diMeConnectionNotification = "hiit.JustUsed.diMeConnectionChange"
    
    // MARK: - General constants
    
    /// String shown in tables when no location string is present
    static let kUnkownLocationString = "Unkown location"
    
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
    