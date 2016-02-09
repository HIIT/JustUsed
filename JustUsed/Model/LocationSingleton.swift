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
import Cocoa
import CoreLocation

/// Keeps track of the location controller, of which we should have only one instance at a time
class LocationSingleton {
    private static let _locationController = LocationController()
    
    static func getCurrentLocation() -> Location? {
        return LocationSingleton._locationController.location
    }
}

class LocationController: NSObject, CLLocationManagerDelegate {
    var locMan: CLLocationManager
    var geoMan: CLGeocoder
    /// It will be true only if we are authorised to retrieve user's location
    var authorised: Bool
    
    /// Stores location in native form
    var location: Location?
    
    required override init() {
        locMan = CLLocationManager()
        geoMan = CLGeocoder()
        
        let authStat = CLLocationManager.authorizationStatus()
        switch authStat {
        case .Denied, .Restricted:
            authorised = false
        default:
            authorised = true
        }
        super.init()
        locMan.delegate = self
        
        if authorised {
            if CLLocationManager.locationServicesEnabled() {
                locMan.desiredAccuracy = kCLLocationAccuracyBest
                locMan.distanceFilter = CLLocationDistance(1000)
                locMan.startUpdatingLocation()
            }
        }
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [AnyObject]) {
        if let loc = locations[0] as? CLLocation {
            geoMan.getDescription(fromLoc: loc) {
                describedLocation in
                self.location = describedLocation
            }
        }
    }
}