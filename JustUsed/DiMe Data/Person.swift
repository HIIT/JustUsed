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

/// A person is represented by this struct (not a class)
class Person: DiMeBase {
    
    var firstName: String = "N/A"
    var lastName: String = "N/A"
    var middleNames: [String] = [String]()
    
    var email: String?
    
    /// Returns the name in a string separated by spaces, such as "FistName MiddleName1 MiddleName2 LastName"
    override var description: String { get {
        var outVal = firstName + " "
        if middleNames.count > 0 {
            for midName in middleNames {
                outVal += midName + " "
            }
        }
        outVal += lastName
        return outVal
    } }
    
    /// Person's hash is based on the hash of all its fields, xorred together
    override var hash: Int { get {
        var outH = firstName.hash
        outH ^= lastName.hash
        for mn in middleNames {
            outH ^= mn.hash
        }
        if let em = email {
            outH ^= em.hash
        }
        return outH
    } }
    
    /// Generates a person from a string. If there is a comma in the string, it is assumed that the first name after the comma, otherwise first name is the first non-whitespace separated string, and last name is the last. Middle names are assumed to all come after the first name if there was a comma, between first and last if there is no comma.
    /// **Fails (returns nil) if the string could not be parsed.**
    init?(fromString string: String) {
        super.init()
        
        if string.containsChar(",") {
            let splitted = string.split(",")
            guard let spl = splitted else {
                return nil
            }
            if spl.count == 2 {
                self.lastName = spl[0]
                
                // check if there are middle names in the following part
                if spl[1].containsChar(" ") {
                    var resplitted = spl[1].split(" ")
                    self.firstName = resplitted!.removeAtIndex(0)
                    if resplitted!.count > 0 {
                        for remName in resplitted! {
                            middleNames.append(remName)
                        }
                    }
                }
                else {
                    self.firstName = spl[1]
                }
            } else {
                return nil
            }
        } else {
            let splitted = string.split(" ")
            guard let spl = splitted else {
                return nil
            }
            if spl.count >= 2 {
                self.firstName = spl.first!
                self.lastName = spl.last!
                if spl.count > 2 {
                    for i in 1..<spl.count - 1 {
                        middleNames.append(spl[i])
                    }
                }
            } else {
                return nil
            }
        }
        
    }
    
    /// Creates a person from dime's json
    init(fromJson json: JSON) {
        self.firstName = json["firstName"].stringValue
        self.lastName = json["lastName"].stringValue
        if let midnames = json["middleNames"].array {
            for midname in midnames {
                self.middleNames.append(midname.stringValue)
            }
        }
        if let em = json["emailAccount"].string {
            self.email = em
        }
    }
    
    override func getDict() -> [String : AnyObject] {
        var retDict = theDictionary
        retDict["firstName"] = firstName
        retDict["lastName"] = lastName
        if middleNames.count > 0 {
            retDict["middleNames"] = middleNames
        }
        if let em = self.email {
            retDict["emailAccount"] = em
        }
        
        return retDict
    }
    
    override func isEqual(object: AnyObject?) -> Bool {
        if let otherPerson = object as? Person {
            if self.firstName != otherPerson.firstName {
                return false
            }
            if self.lastName != otherPerson.lastName {
                return false
            }
            if self.middleNames != otherPerson.middleNames {
                return false
            }
            if let em1 = self.email, em2 = otherPerson.email {
                if em1 != em2 {
                    return false
                }
            }
            
            return true
        } else {
            return false
        }
    }
    
}