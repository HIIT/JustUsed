//
//  AppSingleton.swift
//  JustUsed
//
//  Created by Marco Filetti on 13/08/2015.
//  Copyright (c) 2015 HIIT. All rights reserved.
//

import Foundation
import Cocoa

class AppSingleton {
    static let log = AppSingleton.createLog()
    
    static func createLog() -> XCGLogger {
        var error: NSError? = nil
        var firstLine: String = "Log directory succesfully created / present"
        let tempURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(NSBundle.mainBundle().bundleIdentifier!)
        let tempDirBase = tempURL.path!
        do {
            try NSFileManager.defaultManager().createDirectoryAtPath(tempDirBase, withIntermediateDirectories: true, attributes: nil)
        } catch let error1 as NSError {
            error = error1
            firstLine = "Error creating log directory: " + error!.description
        }
        let logFilePath = tempURL.URLByAppendingPathComponent("XCGLog.log")
        let newLog = XCGLogger.defaultInstance()
        newLog.setup(.Debug, showThreadName: true, showLogLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: logFilePath, fileLogLevel: .Debug)
        newLog.debug(firstLine)
        return newLog
    }
    
}