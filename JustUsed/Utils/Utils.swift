//
//  Utils.swift
//  PeyeDF
//
//  Created by Marco Filetti on 30/06/2015.
//  Copyright (c) 2015 HIIT. All rights reserved.
//
// Contains various functions and utilities not otherwise classified

import Foundation
import Cocoa

// MARK: - Extensions to standard types

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
    
    /// Number of ms since 1/1/1970. Read-only computed property.
    var unixTime: Int { get {
        return Int(round(self.timeIntervalSince1970 * 1000))
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