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
import Contacts

/// Represents an calendar event, as understood by dime
class CalendarEvent: Event {
    
    fileprivate(set) var participants: [Person] = [Person]()
    fileprivate(set) var name: String
    fileprivate(set) var calendar: String
    fileprivate(set) var location: Location?
    fileprivate(set) var locString: String?
    fileprivate(set) var notes: String?
    let id: String
    
    override var hash: Int { get {
        var outH = name.hash
        outH ^= calendar.hash
        if let ls = locString {
            outH ^= ls.hashValue
        }
        if let loc = location {
            outH ^= loc.hashValue
        }
        if let not = notes {
            outH ^= not.hashValue
        }
        for p in participants {
            outH ^= p.hash
        }
        return outH
    } }
    
    init(fromEKEvent event: EKEvent) {
        
        self.id = event.eventIdentifier
        self.name = event.title
        self.calendar = event.calendar.compositeName
        self.notes = event.notes
        if #available(OSX 10.11, *) {
            if let structLoc = event.structuredLocation, let clloc = structLoc.geoLocation {
                location = Location(fromCLLocation: clloc)
            }
        }
        self.locString = event.location
        
        super.init()
        
        if event.hasAttendees, let attendees = event.attendees {
            for attendee in attendees {
                if let name = attendee.name, let part = Person(fromString: name) {
                    // if possible, fetch more data for this person
                    if #available(OSX 10.11, *) {
                        if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
                            do {
                                let store: CNContactStore = AppSingleton.contactStore as! CNContactStore
                                let predicate = attendee.contactPredicate
                                let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: [CNContactEmailAddressesKey as CNKeyDescriptor,CNContactMiddleNameKey as CNKeyDescriptor, CNContactGivenNameKey as CNKeyDescriptor, CNContactFamilyNameKey as CNKeyDescriptor])
                                // put in data from the first returned contact
                                if contacts.count >= 1 {
                                    part.firstName = contacts[0].givenName
                                    part.lastName = contacts[0].familyName
                                    let midName = contacts[0].middleName.trimmed()
                                    if midName != "" {
                                        part.middleNames = [midName]
                                    }
                                    part.email = (contacts[0].emailAddresses[0].value as String)
                                }
                            } catch {
                                Swift.print("Error while fetching an individual contact for \(self.name):\n\(error)")
                            }
                        }
                    }
                    participants.append(part)
                }
            }
        }
        
        setStart(event.startDate)
        setEnd(event.endDate)
        
    }
    
    init(fromJSON json: JSON) {
        
        self.id = json["appId"].stringValue
        self.name = json["name"].stringValue
        self.calendar = json["calendar"].stringValue
        self.locString = json["locString"].string
        self.notes = json["notes"].string
        
        if let participants = json["participants"].array {
            if participants.count > 0 {
                self.participants = [Person]()
                for participant in participants {
                    self.participants.append(Person(fromDime: participant))
                }
            }
        }
        
        if let _ = json["location"].dictionary {
            location = Location(fromJSON: json["location"])
        }
        
        super.init()
        
        let start = Date(timeIntervalSince1970: TimeInterval(json["start"].intValue / 1000))
        let end = Date(timeIntervalSince1970: TimeInterval(json["end"].intValue / 1000))
        setStart(start)
        setEnd(end)
        
    }
    
    /// getDict for calendar is overridden to update return value with internal state.
    override func getDict() -> [String : Any] {
        var retDict = theDictionary  // fetch current values
        
        // update values
        retDict["calendar"] = calendar
        retDict["name"] = name
        if participants.count > 0 {
            var partArray = [[String: Any]]()
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
        if let not = notes {
            retDict["notes"] = not
        }
        
        // required
        retDict["appId"] = id
        // re-define inherited fields
        retDict["@type"] = "CalendarEvent"
        retDict["type"] = "http://www.hiit.fi/ontologies/dime/#CalendarEvent"
        
        return retDict
    }
    
    /// Compares two calendar events, which are equal only if all their fields are equal
    override func isEqual(_ object: Any?) -> Bool {
        if let otherEvent = object as? CalendarEvent {
            if name != otherEvent.name || calendar != otherEvent.calendar || notes != otherEvent.notes {
                return false
            }
            if self.location != otherEvent.location {
                return false
            }
            
            // using redefined version of == for optional collections
            if self.participants == otherEvent.participants {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
}
