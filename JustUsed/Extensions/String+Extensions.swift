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

extension String {
    
    /// Returns SHA1 digest for this string
    func sha1() -> String {
        let data = self.dataUsingEncoding(NSUTF8StringEncoding)!
        var digest = [UInt8](count:Int(CC_SHA1_DIGEST_LENGTH), repeatedValue: 0)
        CC_SHA1(data.bytes, CC_LONG(data.length), &digest)
        let hexBytes = digest.map { String(format: "%02hhx", $0) }
        return hexBytes.joinWithSeparator("")
    }
    
    /// Trims whitespace and newlines using foundation
    func trimmed() -> String {
        let nss: NSString = self
        return nss.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }
    
    /// Checks if this string contains the given character
    func containsChar(theChar: Character) -> Bool {
        for c in self.characters {
            if c == theChar {
                return true
            }
        }
        return false
    }
    
    /// Splits the string, trimming whitespaces, between the given characters (note: slow for very long strings)
    func split(theChar: Character) -> [String]? {
        var outVal = [String]()
        var remainingString = self
        while remainingString.containsChar(theChar) {
            var outString = ""
            var nextChar = remainingString.removeAtIndex(remainingString.startIndex)
            while nextChar != theChar {
                outString.append(nextChar)
                nextChar = remainingString.removeAtIndex(remainingString.startIndex)
            }
            if !outString.trimmed().isEmpty {
                outVal.append(outString.trimmed())
            }
        }
        if !remainingString.trimmed().isEmpty {
            outVal.append(remainingString.trimmed())
        }
        if outVal.count > 0 {
            return outVal
        } else {
            return nil
        }
    }
    
    /// Skips the first x characters
    func skipPrefix(nOfChars: Int) -> String {
        return self.substringFromIndex(self.startIndex.advancedBy(nOfChars))
    }
    
}
