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

/// Keeps track of the location controller, of which we should have only one instance at a time
class LocationSingleton {
    private static let _locationController = LocationController()
    
    static func getLocationString() -> String {
        return LocationSingleton._locationController.locString
    }
}

class LocationController: NSObject, CLLocationManagerDelegate {
    var locMan: CLLocationManager
    var geoMan: CLGeocoder
    /// It will be true only if we are authorised to retrieve user's location
    var authorised: Bool
    
    /// Stores location in string form
    var locString: String
    
    required override init() {
        locMan = CLLocationManager()
        geoMan = CLGeocoder()
        locString = "Not retrieved yet"
        
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
                if let error = error {
                    self.locString = "Error reversing: \(error.description)"
                } else {
                    let placemark = placemarkA![0]
                    self.locString = "Country: \(placemark.country), City: \(placemark.locality), Subloc: \(placemark.subLocality), Detail: \(placemark.thoroughfare)"
                }
                
            }
        }
    }
}