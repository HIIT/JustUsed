//
//  ViewController.swift
//  JustUsed
//
//  Created by Marco Filetti on 11/08/2015.
//  Copyright (c) 2015 HIIT. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDataSource {
    
    // Make sure these constants match the column identifiers
    dynamic let kLastUsedDateTitle = "Last Used Date"
    dynamic let kPathTitle = "File Path"
    dynamic let kIndexTitle = "Index Int"
    dynamic let kBoolPointTitle = "Bool point"
    
    /// Won't re-add a last used items if it was already used within the last x seconds
    let kMinSeconds = 300.0
    
    dynamic var query: NSMetadataQuery?

    @IBOutlet weak var staticTable: NSTableView!
    
    var lutimes = [String]()
    var lupaths = [String]()
    var integers = [String]()
    var booleans = [String]()
    var dates = [NSDate]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        query = NSMetadataQuery()
        staticTable.setDataSource(self)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "queryUpdated:", name: NSMetadataQueryDidUpdateNotification, object: query)
        
        query?.searchScopes = [NSMetadataQueryUserHomeScope]
        
        let startDate = NSDate()
        let predicateFormat = "kMDItemLastUsedDate >= %@"
        var predicateToRun = NSPredicate(format: predicateFormat, argumentArray: [startDate])
        
        // Now, we don't want to include email messages in the result set, so add in an AND that excludes them
        let emailExclusionPredicate = NSPredicate(format: "(kMDItemContentType != 'com.apple.mail.emlx') && (kMDItemContentType != 'public.vcard')", argumentArray: nil)
        predicateToRun = NSCompoundPredicate.andPredicateWithSubpredicates([predicateToRun, emailExclusionPredicate])
        
        query?.predicate = predicateToRun
        query?.startQuery()
    }
    
    @objc func queryUpdated(notification: NSNotification) {
        query?.enumerateResultsUsingBlock(updateBlock)
        staticTable.reloadData()
    }
    
    func updateBlock (input: AnyObject!, index: Int, boolPoint: UnsafeMutablePointer<ObjCBool>) {
        let inputVal = input as! NSMetadataItem
        if index >= dates.count {
            lutimes.append(NSDate().description)
            dates.append(NSDate())
            lupaths.append(inputVal.valueForKey(kMDItemPath as! String)!.description)
            integers.append(index.description)
            if boolPoint.memory {
                booleans.append("true")
            } else {
                booleans.append("false")
            }
        } else {
            // Only re-add items if first time that it was opened was before kMinSeconds from now
            let shiftedDate = NSDate().dateByAddingTimeInterval(-kMinSeconds)
            let previousDate = dates[index]
            if shiftedDate.compare(previousDate) == NSComparisonResult.OrderedDescending {
                lutimes.append(NSDate().description)
                lupaths.append(inputVal.valueForKey(kMDItemPath as! String)!.description)
                integers.append(index.description)
                dates[index] = NSDate()  // update first opening time when re-adding
            }
            if boolPoint.memory {
                booleans.append("true")
            } else {
                booleans.append("false")
            }
        }
    }
    
    /// MARK: Static table data source
    func numberOfRowsInTableView(aTableView: NSTableView) -> Int {
        return count(lutimes)
    }
    
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        if tableColumn!.identifier == kLastUsedDateTitle {
            return lutimes[row]
        } else if tableColumn!.identifier == kPathTitle {
            return lupaths[row]
        } else if tableColumn!.identifier == kIndexTitle {
            return integers[row]
        } else {
            return booleans[row]
        }
    }
    
}

