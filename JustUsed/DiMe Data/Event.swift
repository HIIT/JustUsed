//
//  Event.swift
//  PeyeDF
//
//  Created by Marco Filetti on 27/08/2015.
//  Copyright (c) 2015 HIIT. All rights reserved.
//

import Foundation

/// Note: this class is for subclassing and should not be used directly.
/// subclasses must implement the DiMeAble protocol.
class Event: NSObject {
    
    var json: JSON
    
    /// Must be called by subclasses
    override init() {
        let retDict = [String: AnyObject]()
        
        self.json = JSON(retDict)
        // Make creation date
        json["start"] = JSON(JustUsedConstants.diMeDateFormatter.stringFromDate(NSDate()))
        if let hostname = NSHost.currentHost().name {
            json["origin"] = JSON(hostname)
        }
        
        super.init()
    }
    
    /// Set an end date for this item (otherwise, won't be submitted)
    func setEnd(endDate: NSDate) {
        json["end"] = JSON(JustUsedConstants.diMeDateFormatter.stringFromDate(endDate))
    }
}