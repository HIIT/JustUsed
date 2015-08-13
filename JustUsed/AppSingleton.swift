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
        let tempDirBase = NSTemporaryDirectory().stringByAppendingPathComponent("hiit.JustUsed")
        let logFilePath = tempDirBase.stringByAppendingPathComponent("test.log")
        let newLog = XCGLogger.defaultInstance()
        newLog.setup(logLevel: .Debug, showThreadName: true, showLogLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: logFilePath, fileLogLevel: .Debug)
        return newLog
    }
    
}