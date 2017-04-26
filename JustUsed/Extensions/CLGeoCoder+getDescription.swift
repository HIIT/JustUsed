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
// OTHER DEALINGS IN THE SOFTWARE./

import Foundation
import CoreLocation

extension CLGeocoder {
    
    /// Asynchronously creates a Location object by using a CLLocation and
    /// reversing its location. Calls the given block with a Location that includes description.
    func getDescription(fromLoc inLoc: CLLocation, block: @escaping (_ describedLocation: Location) -> Void) {
        self.reverseGeocodeLocation(inLoc) {
            placemarkA, error in
            
            var outLoc = Location(fromCLLocation: inLoc)
            if let error = error {
                outLoc.descriptionLine = "** Error reversing: \(error)"
            } else {
                let placemark = placemarkA![0]
                var builtString = ""
                if let country = placemark.country {
                    builtString += "Country: \(country)"
                }
                if let locality = placemark.locality {
                    builtString += ", Locality: \(locality)"
                }
                if let subLoc = placemark.subLocality {
                    builtString += ", Neighborhood: \(subLoc)"
                }
                if let street = placemark.thoroughfare {
                    builtString += ", Street: \(street)"
                }
                
                outLoc.descriptionLine = builtString
            }
            
            block(outLoc)
            
        }
    }
    
}
