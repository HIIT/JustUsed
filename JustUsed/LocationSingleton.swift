//
//  LocationSingleton.swift
//  JustUsed
//
//  Created by Marco Filetti on 12/08/2015.
//  Copyright (c) 2015 HIIT. All rights reserved.
//

import Foundation
import Cocoa
import CoreLocation

/// Used to represent locations
struct MyLocation: Equatable {
    
    let locationString: String
    let latitude: Double
    let longitude: Double
 
    static let kUnknownLocation = MyLocation(locationString: "Unknown", latitude: -999, longitude: -999)
}

func ==(lhs: MyLocation, rhs: MyLocation) -> Bool {
    return lhs.longitude == rhs.longitude && lhs.latitude == rhs.latitude
}

/// Keeps track of the location controller, of which we should have only one instance at a time
class LocationSingleton {
    private static let _locationController = LocationController()
    
    static func getCurrentLocation() -> MyLocation? {
        if let currentLoc = LocationSingleton._locationController.location {
            let lat = currentLoc.coordinate.latitude
            let lon = currentLoc.coordinate.latitude
            let str = LocationSingleton._locationController.locString!
            return MyLocation(locationString: str, latitude: lat, longitude: lon)
        } else {
            return nil
        }
    }
}

class LocationController: NSObject, CLLocationManagerDelegate {
    var locMan: CLLocationManager
    var geoMan: CLGeocoder
    /// It will be true only if we are authorised to retrieve user's location
    var authorised: Bool
    
    /// Stores location in string form
    var locString: String?
    
    /// Stores location in native form
    var location: CLLocation?
    
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
        if let retLoc = locations[0] as? CLLocation {
            geoMan.reverseGeocodeLocation(retLoc) {
                placemarkA, error in
            
                self.location = retLoc
                if let error = error {
                    self.locString = "Error reversing: \(error.description)"
                } else {
                    let placemark = placemarkA![0]
                    var builtString = ""
                    if let country = placemark.country {
                        builtString += "Country: \(country)"
                    }
                    if let city = placemark.locality {
                        builtString += ", City: \(city)"
                    }
                    if let subLoc = placemark.subLocality {
                        builtString += ", Neighborhood: \(subLoc)"
                    }
                    if let street = placemark.thoroughfare {
                        builtString += ", Street: \(street)"
                    }
                    
                    self.locString = builtString
                }
                
            }
        }
    }
}