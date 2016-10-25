//
//  Extensions.swift
//  RunTracker
//
//  Created by Ahmed Bakir on 10/25/15.
//  Copyright © 2015 Ahmed Bakir. All rights reserved.
//

import Foundation

extension NSTimeInterval {

    func toString(input: NSTimeInterval) -> (String) {
        let integerTime = Int(input)
        let hours = integerTime / 3600
        let mins = (integerTime / 60) % 60
        let secs = integerTime % 60
        
        var finalString = ""
        
        if hours > 0 {
            finalString += "\(hours) hrs, "
        }
        
        if mins > 0 {
            finalString += "\(mins) mins,"
        }
        
        if secs > 0 {
            finalString += "\(secs) secs"
        }
        return finalString
    }
    
}