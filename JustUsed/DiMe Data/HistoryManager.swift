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
import Quartz

class HistoryManager: NSObject {
    
    /// Set to true to prevent automatic connection checks
    static var forceDisconnect = false
    
    /// Returns a shared instance of this class. This is the designed way of accessing the history manager.
    static let sharedManager = HistoryManager()
    
    /// DiMe connection is checked every time this amount of second passes
    static let kConnectionCheckTime = 5.0
    
    /// Is true if there is a connection to DiMe, and can be used
    fileprivate var dimeAvailable: Bool = false
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        let connectTimer = Timer(timeInterval: HistoryManager.kConnectionCheckTime, target: self, selector: #selector(connectionTimerCheck(_:)), userInfo: nil, repeats: true)
        RunLoop.current.add(connectTimer, forMode: RunLoopMode.commonModes)
    }
    
    /// Callback for connection timer
    func connectionTimerCheck(_ aTimer: Timer) {
        if !HistoryManager.forceDisconnect {
            DiMeSession.dimeConnect()
        }
    }
    
    // MARK: - External functions

}

// MARK: - Protocol implementations

/// Protocol implementations for browser and document history updates
extension HistoryManager: RecentDocumentUpdateDelegate, BrowserHistoryUpdateDelegate {
    
    func newHistoryItems(_ newURLs: [BrowserHistItem]) {
        for newURL in newURLs {
            let sendingToBrowser = UserDefaults.standard.value(forKey: JustUsedConstants.prefSendSafariHistory) as! Bool
            if !newURL.excludedFromDiMe && sendingToBrowser {
                let infoElem = DocumentInformationElement(fromSafariHist: newURL)
                let event = DesktopEvent(infoElem: infoElem, ofType: TrackingType.browser(newURL.browser), withDate: newURL.date, andLocation: newURL.location)
                DiMePusher.sendToDiMe(event)
            }
        }
    }
    
    func newRecentDocument(_ newItem: RecentDocItem) {
        // do all fetching on the utility queue (especially since pdfDoc.getMetadata() blocks)
        DispatchQueue.global(qos: DispatchQoS.QoSClass.utility).async {
            let infoElem = DocumentInformationElement(fromRecentDoc: newItem)
            if infoElem.isPdf {
                let docUrl = URL(fileURLWithPath: newItem.path)
                if let pdfDoc = PDFDocument(url: docUrl) {
                    // try to get metadata from crossref, otherwise get title from pdf's metadata, and as a last resort guess it
                    if let json = pdfDoc.autoCrossref() {
                        infoElem.convertToSciDoc(fromCrossRef: json, keywords: pdfDoc.getKeywordsAsArray())
                    } else if let tit = pdfDoc.getTitle() {
                        infoElem.title = tit
                    } else if let tit = pdfDoc.guessTitle() {
                        infoElem.title = tit
                    }
                }
            }
            let event = DesktopEvent(infoElem: infoElem, ofType: TrackingType.spotlight, withDate: newItem.lastAccessDate, andLocation: newItem.location)
            DiMePusher.sendToDiMe(event)
        }
    }
    
}
