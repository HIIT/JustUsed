//
//  DiMeProtocols.swift
//  PeyeDF
//
//  Created by Marco Filetti on 27/08/2015.
//  Copyright (c) 2015 HIIT. All rights reserved.
//

import Foundation

/// Marks classes and structs that can return themselves in a dictionary
/// where all keys are strings and values can be used in a JSON
protocol Dictionariable {
    
    /// Returns itself in a dict
    func getDict() -> [String: AnyObject]
}

/// This class is made for subclassing. It represents data common to all dime objects (see /dime-server/src/main/java/fi/hiit/dime/data/DiMeData.java in the dime project).
class DiMeBase: NSObject, Dictionariable {
    
    /// Main dictionary storing all data
    ///
    /// **Important**: all sublasses must set these two keys, in order to be decoded by dime:
    /// - @type
    /// - type
    var theDictionary = [String: AnyObject]()
    
    override init() {
        super.init()
    }
    
    func getDict() -> [String : AnyObject] {
        return theDictionary
    }
}