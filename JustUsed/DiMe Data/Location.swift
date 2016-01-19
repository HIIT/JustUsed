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
import CoreLocation

struct Location: Dictionariable, Equatable {
    
    let latitude: Double
    let longitude: Double
    let altitude: Double?
    let horizAccuracy: Double
    let vertAccuracy: Double?
    let bearing: Double?
    let speed: Double?
    var descriptionLine: String?  // not initialized, can be changed later
    
    init(fromCLLocation loc: CLLocation) {
        latitude = loc.coordinate.latitude
        longitude = loc.coordinate.longitude
        horizAccuracy = loc.horizontalAccuracy
        if loc.verticalAccuracy > 0 {
            vertAccuracy = loc.verticalAccuracy
            altitude = loc.altitude
        } else {
            vertAccuracy = nil
            altitude = nil
        }
        if loc.speed > 0 {
            speed = loc.speed
        } else {
            speed = nil
        }
        if loc.course > 0 {
            bearing = loc.course
        } else {
            bearing = nil
        }
    }
    
    /// Returns itself in a (json-able) dict
    func getDict() -> [String: AnyObject] {
        var retDict = [String: AnyObject]()
        
        retDict["latitude"] = latitude
        retDict["longitude"] = longitude
        retDict["horizAccuracy"] = horizAccuracy
        if let altit = altitude {
            retDict["altitude"] = altit
            retDict["vertAccuracy"] = vertAccuracy
        }
        if let sp = speed {
            retDict["speed"] = sp
        }
        if let be = bearing {
            retDict["bearing"] = be
        }
        if let desc = descriptionLine {
            retDict["descriptionLine"] = desc
        }
        return retDict
    }
}

func ==(rhs: Location, lhs: Location) -> Bool {
    if let ralt = rhs.altitude, lalt = lhs.altitude {
        return ralt == lalt && rhs.latitude == lhs.latitude && rhs.longitude == lhs.longitude
    } else {
        return rhs.latitude == lhs.latitude && rhs.longitude == lhs.longitude
    }
}