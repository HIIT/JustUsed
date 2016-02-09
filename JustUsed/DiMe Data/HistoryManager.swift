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

// The history manager is a singleton and keeps track of all history events happening trhough the application.
// This includes, for example, timers which trigger at predefined intervals (such as closing events after a
// specific amount of time has passed, assuming that the user went away from keyboard).
// See https://github.com/HIIT/PeyeDF/wiki/Data-Format for more information

import Foundation
import Alamofire

class HistoryManager: NSObject {
    
    /// Returns a shared instance of this class. This is the designed way of accessing the history manager.
    static let sharedManager = HistoryManager()
    
    /// DiMe connection is checked every time this amount of second passes
    static let kConnectionCheckTime = 5.0
    
    /// Is true if there is a connection to DiMe, and can be used
    private var dimeAvailable: Bool = false
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        let connectTimer = NSTimer(timeInterval: HistoryManager.kConnectionCheckTime, target: self, selector: "connectionTimerCheck:", userInfo: nil, repeats: true)
        NSRunLoop.currentRunLoop().addTimer(connectTimer, forMode: NSRunLoopCommonModes)
    }
    
    /// Callback for connection timer
    func connectionTimerCheck(aTimer: NSTimer) {
        dimeConnect()
    }
    
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
            response in
            if response.result.isFailure {
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
    private func sendToDiMe(dimeData: DiMeBase) {
       
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
                jsonData = try NSJSONSerialization.dataWithJSONObject(dimeData.getDict(), options: options)
            } catch let error1 as NSError {
                error.memory = error1
                jsonData = nil
            }
            
            if jsonData == nil {
                AppSingleton.log.error("Error while deserializing json! This should never happen. \(error)")
                return
            }
            
            Alamofire.request(Alamofire.Method.POST, server_url + "/data/event", parameters: dimeData.getDict(), encoding: Alamofire.ParameterEncoding.JSON, headers: headers).responseJSON {
                response in
                if response.result.isFailure {
                    self.dimeConnectState(false)
                    AppSingleton.log.error("Failure when submitting data to dime:\n\(response.result.error!)")
                } else {
                    // JSON(response.value!) to see what dime replied
                }
            }
            
        }
        
    }
    
}

// MARK: - Protocol implementations

/// Protocol implementations for browser and document history updates
extension HistoryManager: RecentDocumentUpdateDelegate, BrowserHistoryUpdateDelegate {
    
    func newHistoryItems(newURLs: [BrowserHistItem]) {
        for newURL in newURLs {
            let sendingToBrowser = NSUserDefaults.standardUserDefaults().valueForKey(JustUsedConstants.prefSendSafariHistory) as! Bool
            if !newURL.excludedFromDiMe && sendingToBrowser {
                let infoElem = DocumentInformationElement(fromSafariHist: newURL)
                let event = DesktopEvent(infoElem: infoElem, ofType: TrackingType.Browser(newURL.browser), withDate: newURL.date, andLocation: newURL.location)
                sendToDiMe(event)
            }
        }
    }
    
    func newRecentDocument(newItem: RecentDocItem) {
        let infoElem = DocumentInformationElement(fromRecentDoc: newItem)
        let event = DesktopEvent(infoElem: infoElem, ofType: TrackingType.Spotlight, withDate: newItem.lastAccessDate, andLocation: newItem.location)
        sendToDiMe(event)
    }
    
}

/// Protocol implementations for calendar updating