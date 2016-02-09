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

/// Implementers of this method give ways of asynchronously getting a list events
/// and a means to submit new ones (e.g. DiMe).
protocol CalendarHistoryDelegate: class {
    
    /// Asynchronously retrieves all CalendarEvents currently saved in the external history (e.g. currently in dime)
    func fetchCalendarEvents(block: [CalendarEvent] -> Void)
    
    /// Asynchronously submits a new event to the history (e.g. send to dime).
    /// (Must make sure that this was not retrieved eariler in fetchCalendarEvents).
    func sendCalendarEvent(newEvent: CalendarEvent, successBlock: Void -> Void)
}

/// Calendar manager monitors the calendar and sends events found within kBackLook seconds to DiMe.
/// It checks every kInterval, or every time the calendar is updated.
public class CalendarTracker {
    
    /// How often we look for events
    public static let kInterval: NSTimeInterval = 9 * 60  // min * 60 sec
    
    /// How often we look for events already stored in dime (current implementation does not overwrite events which are already present)
    public static let kDiMeFetchInterval: NSTimeInterval = CalendarTracker.kInterval / 2
    
    /// When looking for events in the past, cover this time interval
    public static let kBackLook: NSTimeInterval = CalendarTracker.kBackLook * 2
    
    private let store = EKEventStore()
    
    /// If the user granted access to the calendar, this becomes true
    private(set) var hasAccess: Bool = false
    
    /// All events currently in dime
    private var dimeEvents = [CalendarEvent]()
    
    /// Where are new events fetched from or sent
    var calendarDelegate: CalendarHistoryDelegate
    
    static var sharedInstance: CalendarTracker?
    
    /// Creates a new calendar tracker, which uses the given object to fetch / update
    /// calendar events.
    init(calendarDelegate: CalendarHistoryDelegate) {
        self.calendarDelegate = calendarDelegate
        store.requestAccessToEntityType(.Event) {
            (granted, error) in
            if granted {
                self.hasAccess = true
                
                // check calendar when an event is modified
                NSNotificationCenter.defaultCenter().addObserver(self, selector: "getCurrentEvents:", name: EKEventStoreChangedNotification, object: self.store)
                // check calendar regularly
                NSTimer.scheduledTimerWithTimeInterval(CalendarTracker.kInterval, target: self, selector: "getCurrentEvents:", userInfo: nil, repeats: true)
                // repeatedly fetch all events from dime to avoid sending too many
                NSTimer.scheduledTimerWithTimeInterval(CalendarTracker.kDiMeFetchInterval, target: self, selector: "getDiMeEvents:", userInfo: nil, repeats: true)
                // fetch the current events in 5 seconds, to allow dime to come online
                let callTime = dispatch_time(DISPATCH_TIME_NOW,
                                     Int64(5 * Double(NSEC_PER_SEC)))
                dispatch_after(callTime, dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
                    self.getCurrentEvents(nil)
                }
            }
            if let err = error {
                AppSingleton.log.error("Error while asking permission to access calendars:\n\(err)")
            }
        }
        CalendarTracker.sharedInstance = self
    }
    
    // MARK: - Accessors
    
    /// Returns an array containing all calendars residing on the user's device.
    /// Nil if we don't have permission to access them.
    func calendarNames() -> [String]? {
        if hasAccess {
            var retVal = [String]()
            for cal in store.calendarsForEntityType(.Event) {
                retVal.append(cal.title)
            }
            return retVal
        } else {
            return nil
        }
    }
    
    // MARK: - Private
    
    /// Get events which just-passed. Current event is defined as the latest event that started from kBackLook seconds ago until now, in all calendars.
    /// - parameter hitObject: Whatever is calling this (notification or timer)
    @objc private func getCurrentEvents(hitObject: AnyObject?) {
        let sinceTime: NSTimeInterval = CalendarTracker.kBackLook
        
        let allCalendars = store.calendarsForEntityType(.Event)
        let predicate = store.predicateForEventsWithStartDate(NSDate().dateByAddingTimeInterval(-sinceTime), endDate: NSDate(), calendars: allCalendars)
        let allEvents = store.eventsMatchingPredicate(predicate)
        for event in allEvents {
            let calEvent = CalendarEvent(fromEKEvent: event)
            if !dimeEvents.contains(calEvent) {
                calendarDelegate.sendCalendarEvent(calEvent) {
                    // if successful, this block is called. Add given event to list.
                    self.dimeEvents.append(calEvent)
                }
            }
        }
    }
    
    /// Get events found in dime
    @objc private func getDiMeEvents(timer: NSTimer?) {
        calendarDelegate.fetchCalendarEvents() {
            events in
            self.dimeEvents = events
        }
    }
    
}