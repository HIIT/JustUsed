//
//  ResourcedEvent.swift
//  PeyeDF
//
//  Created by Marco Filetti on 25/08/2015.
//  Copyright (c) 2015 HIIT. All rights reserved.
//

import Foundation

/// Used to send the first-time file opening event
class DesktopEvent: Event, DiMeAble, Dictionariable {
    
    init(infoElem: DocumentInformationElement, ofType type: TrackingType, withDate date: NSDate) {
        super.init()
        self.json["targettedResource"] = JSON(infoElem.getDict())
        switch type {
        case .Safari:
            json["actor"] = JSON("JustUsed_Safari")
        case .Spotlight:
            json["actor"] = JSON("JustUsed_Spotlight")
        }
        json["start"] = JSON(JustUsedConstants.diMeDateFormatter.stringFromDate(date))
        setDiMeDict()
    }
    
    func setDiMeDict() {
        self.json["@type"] = JSON("DesktopEvent")
        self.json["type"] = JSON("http://www.hiit.fi/ontologies/dime/#DesktopEvent")
    }
    
    func getDict() -> [String : AnyObject] {
        return json.dictionaryObject!
    }
    
}

enum TrackingType {
    case Safari
    case Spotlight
}