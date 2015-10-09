//
//  HistoryManager.swift
//  PeyeDF
//
//  Created by Marco Filetti on 26/08/2015.
//  Copyright (c) 2015 HIIT. All rights reserved.
//

// The history manager is a singleton and keeps track of all history events happening trhough the application.
// This includes, for example, timers which trigger at predefined intervals (such as closing events after a
// specific amount of time has passed, assuming that the user went away from keyboard).
// See https://github.com/HIIT/PeyeDF/wiki/Data-Format for more information

import Foundation
import Alamofire

class HistoryManager: SpotlightHistoryUpdateDelegate, SafariHistoryUpdateDelegate {
    
    /// Returns a shared instance of this class. This is the designed way of accessing the history manager.
    static let sharedManager = HistoryManager()
    
    /// Is true if there is a connection to DiMe, and can be used
    private var dimeAvailable: Bool = false
    
    // MARK: - External functions
    
    /// Returns true if dime is available
    func isDiMeAvailable() -> Bool {
        return dimeAvailable
    }
    
    /// Attempts to connect to dime. Sends a notification if we succeeded / failed
    func dimeConnect() {
        let server_url: String = NSUserDefaults.standardUserDefaults().valueForKey(JustUsedConstants.prefDiMeServerURL) as! String
        let user: String = NSUserDefaults.standardUserDefaults().valueForKey(JustUsedConstants.prefDiMeServerUserName) as! String
        let password: String = NSUserDefaults.standardUserDefaults().valueForKey(JustUsedConstants.prefDiMeServerPassword) as! String
        
        let credentialData = "\(user):\(password)".dataUsingEncoding(NSUTF8StringEncoding)!
        let base64Credentials = credentialData.base64EncodedStringWithOptions([])
        
        let headers = ["Authorization": "Basic \(base64Credentials)"]
        
        let dictionaryObject = ["test": "test"]
        
        Alamofire.request(Alamofire.Method.POST, server_url + "/ping", parameters: dictionaryObject, encoding: Alamofire.ParameterEncoding.JSON, headers: headers).responseJSON {
            _, _, response in
            if response.isFailure {
                // connection failed
                self.dimeConnectState(false)
            } else {
                // succesfully connected
                self.dimeConnectState(true)
            }
        }
    }
    
    /// Disconnects from dime
    func dimeDisconnect() {
        self.dimeConnectState(false)
    }
    
    // MARK: - Protocol implementation
    
    func newHistoryItems(newURLs: [SafariHistItem]) {
        for newURL in newURLs {
            let infoElem = DocumentInformationElement(fromSafariHist: newURL)
            let event = DesktopEvent(infoElem: infoElem, ofType: TrackingType.Safari, withDate: newURL.date)
            sendDictToDime(event.getDict())
        }
    }
    
    func newSpotlightData(newItem: SpotlightHistItem) {
        let infoElem = DocumentInformationElement(fromSpotlightHist: newItem)
        let event = DesktopEvent(infoElem: infoElem, ofType: TrackingType.Spotlight, withDate: newItem.lastAccessDate)
        sendDictToDime(event.getDict())
    }
    
    // MARK: - Internal functions
    
    /// Connection to dime successful / failed
    private func dimeConnectState(success: Bool) {
        if !success {
            self.dimeAvailable = false
            NSNotificationCenter.defaultCenter().postNotificationName(JustUsedConstants.diMeConnectionNotification, object: self, userInfo: nil)
        } else {
            // succesfully connected
            self.dimeAvailable = true
            NSNotificationCenter.defaultCenter().postNotificationName(JustUsedConstants.diMeConnectionNotification, object: self, userInfo: nil)
        }
    }
    
    /// Send the given dictionary to DiMe (assumed to be in correct form due to the use of public callers of this method)
    private func sendDictToDime(dictionaryObject: [String: AnyObject]) {
       
        if dimeAvailable {
            
            let server_url: String = NSUserDefaults.standardUserDefaults().valueForKey(JustUsedConstants.prefDiMeServerURL) as! String
            let user: String = NSUserDefaults.standardUserDefaults().valueForKey(JustUsedConstants.prefDiMeServerUserName) as! String
            let password: String = NSUserDefaults.standardUserDefaults().valueForKey(JustUsedConstants.prefDiMeServerPassword) as! String
            
            let credentialData = "\(user):\(password)".dataUsingEncoding(NSUTF8StringEncoding)!
            let base64Credentials = credentialData.base64EncodedStringWithOptions([])
            
            let headers = ["Authorization": "Basic \(base64Credentials)"]
            
            let error = NSErrorPointer()
            let options = NSJSONWritingOptions.PrettyPrinted

            let jsonData: NSData?
            do {
                jsonData = try NSJSONSerialization.dataWithJSONObject(dictionaryObject, options: options)
            } catch let error1 as NSError {
                error.memory = error1
                jsonData = nil
            }
            
            if jsonData == nil {
                AppSingleton.log.error("Error while deserializing json! This should never happen. \(error)")
                return
            }
            
            Alamofire.request(Alamofire.Method.POST, server_url + "/data/event", parameters: dictionaryObject, encoding: Alamofire.ParameterEncoding.JSON, headers: headers).responseJSON {
                _, _, response in
                if response.isFailure {
                    self.dimeConnectState(false)
                } else {
                    // JSON(response.value!) to see what dime replied
                }
            }
            
        }
        
    }
    
}
