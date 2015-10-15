//
//  Location.swift
//  JustUsed
//
//  Created by Marco Filetti on 15/10/2015.
//  Copyright © 2015 HIIT. All rights reserved.
//

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