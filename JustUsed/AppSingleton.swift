//
//  AppSingleton.swift
//  JustUsed
//
//  Created by Marco Filetti on 13/08/2015.
//  Copyright (c) 2015 HIIT. All rights reserved.
//

import Foundation

class AppSingleton {
    static let log = AppSingleton.createLog()
    
    static func createLog() -> XCGLogger {
        var error: NSError? = nil
        var firstLine: String = "Log directory succesfully created / present"
        let tempDirBase = NSTemporaryDirectory().stringByAppendingPathComponent("hiit.JustUsed")
            if !NSFileManager.defaultManager().createDirectoryAtPath(tempDirBase, withIntermediateDirectories: true, attributes: nil, error: &error) {
                firstLine = "Error creating log directory: " + error!.description
            }
        let logFilePath = tempDirBase.stringByAppendingPathComponent("XCGLog.log")
        let newLog = XCGLogger.defaultInstance()
        newLog.setup(logLevel: .Debug, showThreadName: true, showLogLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: logFilePath, fileLogLevel: .Debug)
        newLog.debug(firstLine)
        return newLog
    }
    
}