//
//  RecentDocumentsTracker.swift
//  JustUsed
//
//  Created by Marco Filetti on 30/10/2015.
//  Copyright © 2015 HIIT. All rights reserved.
//

import Foundation
import Cocoa

/// New recent document items are represented by this struct
struct RecentDocItem: Equatable {
    /// Date that this item was last accessed
    var lastAccessDate: NSDate
    /// Path of this file on disk
    let path: String
    /// Location when this file was last opened, if available
    var location: Location?
    /// Mime type
    let mime: String
    /// What program opened this file
    let source: String
}

func ==(lhs:RecentDocItem, rhs: RecentDocItem) -> Bool {
    return lhs.path == rhs.path && lhs.source == rhs.source && lhs.mime == rhs.mime
}

/// Protocol to notify a delegate that a new recent document was found
protocol RecentDocumentUpdateDelegate {
    
    /// Tells the delegate that new data is available
    func newRecentDocument(newItem: RecentDocItem)
}

/// This class should be subclassed by all items that find recent documents, such as SpotlightTracker or RecentPlistTracker
class RecentDocumentsTracker: NSObject {
    
    internal var recentDocumentUpdateDelegates = [RecentDocumentUpdateDelegate]()
    
    func addRecentDocumentUpdateDelegate(newRecentDocDelegate: RecentDocumentUpdateDelegate) {
        recentDocumentUpdateDelegates.append(newRecentDocDelegate)
    }
    
    required override init() {
        super.init()
    }
}