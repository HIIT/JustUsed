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

/// Used to send the first-time file opening event
class DesktopEvent: Event {
    
    init(infoElem: DocumentInformationElement, ofType type: TrackingType, withDate date: Date, andLocation location: Location?) {
        super.init()
        
        theDictionary["targettedResource"] = infoElem.getDict() as AnyObject
        switch type {
        case .spotlight:
            theDictionary["actor"] = "JustUsed_Spotlight" as AnyObject
        case let .browser(browser):
            theDictionary["actor"] = "JustUsed_\(browser)" as AnyObject
        }
        theDictionary["start"] = JustUsedConstants.diMeDateFormatter.string(from: date)
        
        if let loc = location {
            theDictionary["location"] = loc.getDict() as AnyObject
        }
        
        theDictionary["@type"] = "DesktopEvent" as AnyObject
        theDictionary["type"] = "http://www.hiit.fi/ontologies/dime/#DesktopEvent" as AnyObject
    }
}

enum TrackingType {
    case browser(BrowserType)
    case spotlight
}
