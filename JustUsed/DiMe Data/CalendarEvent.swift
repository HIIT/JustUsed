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
import EventKit

/// Represents an calendar event, as understood by dime
class CalendarEvent: Event {
    
    private(set) var participants: [Person]?
    private(set) var name: String
    private(set) var calendar: String
    private(set) var location: Location?
    private(set) var locString: String?
    let id: String
    
    init(fromEKEvent event: EKEvent) {
        
        self.id = event.eventIdentifier
        self.name = event.title
        self.calendar = event.calendar.title
        if #available(OSX 10.11, *) {
            if let structLoc = event.structuredLocation, clloc = structLoc.geoLocation {
                location = Location(fromCLLocation: clloc)
            }
        }
        self.locString = event.location
        
        super.init()
        
        setStart(event.startDate)
        setEnd(event.endDate)
        
    }
    
    init(fromJSON json: JSON) {
        
        self.id = json["appId"].stringValue
        self.name = json["name"].stringValue
        self.calendar = json["calendar"].stringValue
        self.locString = json["locString"].string
        
        if let participants = json["participants"].array {
            if participants.count > 0 {
                self.participants = [Person]()
                for participant in participants {
                    self.participants!.append(Person(fromJson: participant))
                }
            }
        }
        
        if let _ = json["location"].dictionary {
            location = Location(fromJSON: json["location"])
        }
        
        super.init()
        
        let start = NSDate(timeIntervalSince1970: NSTimeInterval(json["start"].intValue / 1000))
        let end = NSDate(timeIntervalSince1970: NSTimeInterval(json["end"].intValue / 1000))
        setStart(start)
        setEnd(end)
        
    }
    
    /// getDict for calendar is overridden to update return value with internal state.
    override func getDict() -> [String : AnyObject] {
        var retDict = theDictionary  // fetch current values
        
        // update values
        retDict["calendar"] = calendar
        retDict["name"] = name
        if let participants = participants {
            var partArray = [[String: AnyObject]]()
            for participant in participants {
                partArray.append(participant.getDict())
            }
            retDict["participants"] = partArray
        }
        
        if let loc = location {
            retDict["location"] = loc.getDict()
        }
        if let ls = locString {
            retDict["locString"] = ls
        }
        
        // required
        retDict["appId"] = id
        // re-define inherited fields
        retDict["@type"] = "CalendarEvent"
        retDict["type"] = "http://www.hiit.fi/ontologies/dime/#CalendarEvent"
        
        return retDict
    }
}