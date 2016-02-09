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
import Contacts

class AppSingleton {
    /// Returns true if OS X version is greater than 10.10
    static let isElCapitan = NSProcessInfo.processInfo().operatingSystemVersion.majorVersion == 10 &&
                             NSProcessInfo.processInfo().operatingSystemVersion.minorVersion == 11
    
    /// The contact store used to fetch contacts (to fill out calendar events).
    /// Is nil if we can't / are not allowed to access it.
    /// If allowed, the object is not nil and should be cast to a CNContactStore (only for
    /// el capitan and above).
    static private(set) var contactStore: AnyObject? = AppSingleton.initiateContactsRequest()
    
    static let log = AppSingleton.createLog()
    static private(set) var logsURL = NSURL()
    
    /// Ref to filemanager for convenience
    static let fileManager = NSFileManager.defaultManager()
    
    static func createLog() -> XCGLogger {
        let dateFormat = "Y'-'MM'-'d'T'HH':'mm':'ssZ"  // date format for string appended to log
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = dateFormat
        let appString = dateFormatter.stringFromDate(NSDate())
        
        var firstLine: String = "Log directory succesfully created / present"
        let tempURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(NSBundle.mainBundle().bundleIdentifier!)
        do {
            try NSFileManager.defaultManager().createDirectoryAtURL(tempURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            firstLine = "Error creating log directory: \(error)"
        }
        AppSingleton.logsURL = tempURL
        let logFilePath = tempURL.URLByAppendingPathComponent("XCGLog_\(appString).log")
        let newLog = XCGLogger.defaultInstance()
        newLog.setup(.Debug, showThreadName: true, showLogLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: logFilePath, fileLogLevel: .Debug)
        newLog.debug(firstLine)
        return newLog
    }
    
    /// Returns true if we are on el capitan (or another supported platform)
    /// and we can access the user's contacts
    private static func initiateContactsRequest() -> AnyObject? {
        if #available(OSX 10.11, *) {
            let store = CNContactStore()
            store.requestAccessForEntityType(.Contacts) {
                granted, error in
                if let err = error {
                    AppSingleton.log.error("Error while accessing contact store:\n\(err)")
                }
            }
            return store
        } else {
            return nil
        }
    }
    
}