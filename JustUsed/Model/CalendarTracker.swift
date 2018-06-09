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

/// Tracks calendars event this way: it checks for events that are stored in the calendar
/// ±24 hours from now. Sends all of them, if not in the calendar exclusion list, to dime, updating
/// old events. Repeats this procedure every hour, or every time the calendar is modified externally.
/// Also does a check 90 seconds from initialisation.
open class CalendarTracker {
    
    /// How often we look for events
    open static let kInterval: TimeInterval = 60 * 60  // one hour
    
    /// When looking for events in the past, cover this time interval
    open static let kLookBack: TimeInterval = 24 * 60 * 60  // 24 hours back
    
    /// When looking for events in the future, cover this time interval
    open static let kLookAhead: TimeInterval = 24 * 60 * 60  // 24 hours ahead
    
    fileprivate let store = EKEventStore()
    
    /// If the user granted access to the calendar, this becomes true
    fileprivate(set) var hasAccess: Bool = false
    
    /// Creates a new calendar tracker, which uses the given object to fetch / update
    /// calendar events.
    init() {
        store.requestAccess(to: .event) {
            (granted, error) in
            if granted {
                self.hasAccess = true
                
                // check calendar when an event is modified
                NotificationCenter.default.addObserver(self, selector: #selector(self.submitCurrentEvents(_:)), name: NSNotification.Name.EKEventStoreChanged, object: self.store)
                // check calendar regularly
                Timer.scheduledTimer(timeInterval: CalendarTracker.kInterval, target: self, selector: #selector(self.submitCurrentEvents(_:)), userInfo: nil, repeats: true)
                // fetch the current events in 90 seconds, to allow dime to come online and the user to set preferences
                let callTime = DispatchTime.now() + Double(Int64(90 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.global(qos: DispatchQoS.QoSClass.background).asyncAfter(deadline: callTime) {
                    self.submitCurrentEvents(nil)
                }
            }
            if let err = error {
                Swift.print("Error while asking permission to access calendars:\n\(err)")
            }
        }
    }
    
    // MARK: - External functions
    
    /// Returns an array containing all calendars residing on the user's device.
    /// Nil if we don't have permission to access them.
    /// Calendar names are in the format account.title (e.g. iCloud.work)
    func calendarNames() -> [String]? {
        if hasAccess {
            var retVal = [String]()
            for cal in store.calendars(for: .event) {
                retVal.append("\(cal.source.title).\(cal.title)")
            }
            return retVal
        } else {
            return nil
        }
    }
    
    /// Sets the exclude value for a given calendar. Returns an updated exclude list (only
    /// (calendars which actually exist can be excluded). Updates NSUserDefaults.
    func setExcludeValue(exclude: Bool, calendar: String) -> [String] {
        var currentExcludes = UserDefaults.standard.value(forKey: JustUsedConstants.prefExcludeCalendars) as! [String]
        let _calendars = calendarNames()
        guard let calendars = _calendars else {
            return []
        }
        
        // Exclude / include only if not duplicate
        if exclude {
            if !currentExcludes.contains(calendar) {
                currentExcludes.append(calendar)
            }
        } else {
            if currentExcludes.contains(calendar) {
                let i = currentExcludes.index(of: calendar)!
                currentExcludes.remove(at: i)
            }
        }
        
        // Create new list of things that actually exist and are excluded
        var actualExcludes = [String]()
        for excl in currentExcludes {
            if calendars.contains(excl) && !actualExcludes.contains(excl) {
                actualExcludes.append(excl)
            }
        }
        
        UserDefaults.standard.setValue(actualExcludes, forKey: JustUsedConstants.prefExcludeCalendars)
        UserDefaults.standard.synchronize()
        
        return actualExcludes
    }
    
    /// Returns a dictionary, one entry per calendar, where the value is whether the
    /// calendar is excluded
    /// Returns nil if there are no valid calendars
    func getExcludeCalendars() -> [String: Bool]? {
        let currentExcludes = UserDefaults.standard.value(forKey: JustUsedConstants.prefExcludeCalendars) as! [String]
        let _calendars = calendarNames()
        guard let calendars = _calendars else {
            return nil
        }
        var retVal = [String: Bool]()
        for cal in calendars {
            retVal[cal] = currentExcludes.contains(cal)
        }
        
        return retVal
    }
    
    /// Submits calendar events to dime.
    /// - parameter dataMine: if true, looks for all possible events two years before and after now.
    func submitEvents(dataMine: Bool = false) {
        guard let excludeCalendars = getExcludeCalendars() else {
            return
        }
        
        let sinceDate: Date
        let thenDate: Date
        
        if dataMine {
            sinceDate = Date().yearOffset(-2)
            thenDate = Date().yearOffset(2)
        } else {
            let sinceTime: TimeInterval = CalendarTracker.kLookBack
            let thenTime: TimeInterval = CalendarTracker.kLookAhead
            sinceDate = Date().addingTimeInterval(-sinceTime)
            thenDate = Date().addingTimeInterval(+thenTime)
        }
        
        var fetchCalendars = store.calendars(for: .event)
        fetchCalendars = fetchCalendars.filter({excludeCalendars[$0.compositeName] == false})
        let predicate = store.predicateForEvents(withStart: sinceDate, end: thenDate, calendars: fetchCalendars)
        let allEvents = store.events(matching: predicate)
        for event in allEvents {
            let calEvent = CalendarEvent(fromEKEvent: event)
            DiMePusher.sendToDiMe(calEvent)
        }
    }
    
    // MARK: - Timer / notification callbacks
    
    /// Submits events which just-passed. Current event is defined as the latest event that started from kLookBack until kLookAhead.
    /// - parameter hitObject: Whatever is calling this (notification or timer)
    @objc fileprivate func submitCurrentEvents(_ hitObject: AnyObject?) {
        submitEvents()
    }
    
}
