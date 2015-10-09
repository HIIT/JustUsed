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

/// Marks dime "container" objects that can send themselves to DiMe
protocol DiMeAble {
    
    /// Set DiMe Dictionary. Can be called directly by class/subclass' own initializer.
    /// This method must set the following fields in its own json:
    ///
    /// - @type
    /// - type
    func setDiMeDict()
}
