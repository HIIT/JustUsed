//
//  JustUsedConstants.swift
//  JustUsed
//
//  Created by Marco Filetti on 13/08/2015.
//  Copyright (c) 2015 HIIT. All rights reserved.
//

import Foundation

class JustUsedConstants {
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
    