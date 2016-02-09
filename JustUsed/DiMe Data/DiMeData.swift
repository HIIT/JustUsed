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

/// Marks classes and structs that can return themselves in a dictionary
/// where all keys are strings and values can be used in a JSON
protocol Dictionariable {
    
    /// Returns itself in a JSON-Serializable dict
    func getDict() -> [String: AnyObject]
}

/// This class is made for subclassing. It represents data common to all dime objects (see /dime-server/src/main/java/fi/hiit/dime/data/DiMeData.java in the dime project).
class DiMeBase: NSObject, Dictionariable {
    
    /// Main dictionary storing all data
    ///
    /// **Important**: all sublasses must set these two keys, in order to be decoded by dime:
    /// - @type
    /// - type
    var theDictionary = [String: AnyObject]()
    
    override init() {
        theDictionary["actor"] = "JustUsed"
        super.init()
    }
    
    func getDict() -> [String : AnyObject] {
        return theDictionary
    }
}