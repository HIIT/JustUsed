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

/// Used to retrieve the current calendar event title.
/// Current title is defined as the name of the last event that occurred ± 5 minutes from now.
///
/// To get the current event title: `CalendarManager.sharedInstance.currentEventName`
public class CalendarManager {
    
    private let store = EKEventStore()
    
    static let sharedInstance = CalendarManager()
    
    /// The name of the current event. If there is no current event, or calendar(s) could not be
    /// accessed, this value is nil.
    public var currentEventName: String?
    
    private init() {
        store.requestAccessToEntityType(.Event) {
            result in
            if result.0 {
                NSNotificationCenter.defaultCenter().addObserver(self, selector: "getCurrentEvent:", name: EKEventStoreChangedNotification, object: self.store)
                self.getCurrentEvent(nil)
            }
        }
    }
    
    /// Get the current event. Current event is defined as the latest event that started from 5 minutes ago until now, in all calendars.
    @objc private func getCurrentEvent(notification: NSNotification?) {
        let sinceTime: NSTimeInterval = 5 * 60  // number of minutes ago * 60
        
        let allCalendars = store.calendarsForEntityType(.Event)
        let predicateSinceFiveMinutesAgo = store.predicateForEventsWithStartDate(NSDate().dateByAddingTimeInterval(-sinceTime), endDate: NSDate().dateByAddingTimeInterval((sinceTime)), calendars: allCalendars)
        var allEvents = store.eventsMatchingPredicate(predicateSinceFiveMinutesAgo)
        if allEvents.count > 0 {
            allEvents.sortInPlace({$1.compareStartDateWithEvent($0) == NSComparisonResult.OrderedAscending})
            currentEventName = allEvents[0].title
        } else {
            currentEventName = nil
        }
        Swift.print(currentEventName)
    }
    
}