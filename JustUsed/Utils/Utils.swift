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

// Contains various functions and utilities not otherwise classified

import Foundation
import Cocoa
import Quartz

// MARK: - Extensions to standard types

extension PDFDocument {
    
    /// Returns a trimmed plain text of the data contained in the document, nil not preset
    func getText() -> String? {
        
        var trimmedText = string()
        trimmedText = trimmedText.stringByReplacingOccurrencesOfString("\u{fffc}", withString: "")
        trimmedText = trimmedText.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) // get trimmed version of all text
        trimmedText = trimmedText.stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet()) // trim newlines
        trimmedText = trimmedText.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) // trim again
        if trimmedText.characters.count > 5 {  // we assume the document does contain useful text if there are more than 5 characters remaining
            return trimmedText
        } else {
            return nil
        }
    }
    
}

extension NSURL {
    
    /// Get mime type
    func getMime() -> String? {
        var mime: String?
        let UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, self.pathExtension!, nil)
        let MIMEType = UTTypeCopyPreferredTagWithClass(UTI!.takeRetainedValue(), kUTTagClassMIMEType)
        var isDir = ObjCBool(false)
        if let mimet = MIMEType {
            mime = mimet.takeRetainedValue() as String
        } else if NSFileManager.defaultManager().fileExistsAtPath(self.path!, isDirectory: &isDir) {
            if isDir {
                mime = "application/x-directory"
            } else {
                // if the file exists but it's not a directory and has no known mime type
                var foundEncoding: UInt = 0
                if let _ = try? NSString(contentsOfURL: self, usedEncoding: &foundEncoding) {
                    mime = "text/plain"
                } else {
                    mime = "application/octet-stream"
                }
            }
        }
        return mime
    }
}

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

}

extension String {
    
    /// Returns SHA1 digest for this string
    func sha1() -> String {
        let data = self.dataUsingEncoding(NSUTF8StringEncoding)!
        var digest = [UInt8](count:Int(CC_SHA1_DIGEST_LENGTH), repeatedValue: 0)
        CC_SHA1(data.bytes, CC_LONG(data.length), &digest)
        let hexBytes = digest.map { String(format: "%02hhx", $0) }
        return hexBytes.joinWithSeparator("")
    }
}