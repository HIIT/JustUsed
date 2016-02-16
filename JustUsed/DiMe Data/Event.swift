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

/// Note: this class is for subclassing and should not be used directly.
/// subclasses must implement the DiMeAble protocol.
class Event: DiMeBase {
    
    /// Must be called by subclasses
    override init() {
        super.init()
        
        // Make creation date
        theDictionary["start"] = JustUsedConstants.diMeDateFormatter.stringFromDate(NSDate())
        if let hostname = NSHost.currentHost().name {
            theDictionary["origin"] = hostname
        }
    
        // set dime-required fields (can be overwritten by subclasses)
        theDictionary["actor"] = "JustUsed"
        theDictionary["@type"] = "Event"
        theDictionary["type"] = "http://www.hiit.fi/ontologies/dime/#Event"
    }
    
    /// Set an end date for this item (otherwise, won't be submitted)
    func setEnd(endDate: NSDate) {
        theDictionary["end"] = JustUsedConstants.diMeDateFormatter.stringFromDate(endDate)
    }
    
    /// Set a start date for this item (updates old value)
    func setStart(endDate: NSDate) {
        theDictionary["start"] = JustUsedConstants.diMeDateFormatter.stringFromDate(endDate)
    }
}