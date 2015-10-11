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
    
    init(infoElem: DocumentInformationElement, ofType type: TrackingType, withDate date: NSDate) {
        super.init()
        
        theDictionary["targettedResource"] = infoElem.getDict()
        switch type {
        case .Safari:
            theDictionary["actor"] = "JustUsed_Safari"
        case .Spotlight:
            theDictionary["actor"] = "JustUsed_Spotlight"
        }
        theDictionary["start"] = JustUsedConstants.diMeDateFormatter.stringFromDate(date)
        
        theDictionary["@type"] = "DesktopEvent"
        theDictionary["type"] = "http://www.hiit.fi/ontologies/dime/#DesktopEvent"
    }
}

enum TrackingType {
    case Safari
    case Spotlight
}