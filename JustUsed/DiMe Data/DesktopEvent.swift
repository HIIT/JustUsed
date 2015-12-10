//
//  ResourcedEvent.swift
//  PeyeDF
//
//  Created by Marco Filetti on 25/08/2015.
//  Copyright (c) 2015 HIIT. All rights reserved.
//

import Foundation

/// Used to send the first-time file opening event
class DesktopEvent: Event {
    
    init(infoElem: DocumentInformationElement, ofType type: TrackingType, withDate date: NSDate, andLocation location: Location?) {
        super.init()
        
        theDictionary["targettedResource"] = infoElem.getDict()
        switch type {
        case .Spotlight:
            theDictionary["actor"] = "JustUsed_Spotlight"
        case let .Browser(browser):
            theDictionary["actor"] = "JustUsed_\(browser)"
        }
        theDictionary["start"] = JustUsedConstants.diMeDateFormatter.stringFromDate(date)
        
        if let loc = location {
            theDictionary["location"] = loc.getDict()
        }
        
        theDictionary["@type"] = "DesktopEvent"
        theDictionary["type"] = "http://www.hiit.fi/ontologies/dime/#DesktopEvent"
    }
}

enum TrackingType {
    case Browser(BrowserType)
    case Spotlight
}
