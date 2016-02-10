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

extension NSDate {
    
    /// Number of ms since 1/1/1970.
    var unixTime_ms: Int { get {
        return Int(round(self.timeIntervalSince1970 * 1000))
        }
    }
    
    /// Creates a date from a unix time in microsec
    convenience init(fromUnixTime_μs μs: Int) {
        self.init(timeIntervalSince1970: Double(μs) / 1000000)
    }
    
    /// Number of microsec since 1/1/1970.
    var unixTime_μs: Int { get {
        return Int(round(self.timeIntervalSince1970 * 1000000))
        }
    }
    
    /// Creates a date from a ldap timestamp.
    convenience init(fromLdapTime lt: Int) {
        let unixtime_s = Double(lt)/1000000-11644473600
        self.init(timeIntervalSince1970: unixtime_s)
    }
    
    /// Returns the corresponding date as a LDAP timestamp.
    var ldapTime: Int { get {
        return Int(round(1000000 * (11644473600 + self.timeIntervalSince1970)))
        }
    }
    
    /// Returns the current time in a short format, e.g. 16:30.45
    /// Use this to pass dates to DiMe
    static func shortTime() -> String {
        let currentDate = NSDate()
        let dsf = NSDateFormatter()
        dsf.dateFormat = "HH:mm.ss"
        return dsf.stringFromDate(currentDate)
    }
    
    /// Returns an NSDate that representing this date plus the given offset.
    /// e.g. NSDate().yearOffset(2) represents two years from now.
    func yearOffset(year: Int) -> NSDate {
        let calendar = NSCalendar(identifier: NSCalendarIdentifierGregorian)!
        let addComponents = NSDateComponents()
        addComponents.year = year
        return calendar.dateByAddingComponents(addComponents, toDate: self, options: .MatchStrictly)!
    }
    
}

