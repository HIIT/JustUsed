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