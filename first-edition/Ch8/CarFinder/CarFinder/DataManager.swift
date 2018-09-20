//
//  DataManager.swift
//  CarFinder
//
//  Created by Ahmed Bakir on 10/28/15.
//  Copyright © 2015 Ahmed Bakir. All rights reserved.
//

import Foundation
import CoreLocation

class DataManager {
    static let sharedInstance = DataManager()
    //var locations = [CLLocation]()
    var locations : [CLLocation]
    
    private init() {
        locations = [CLLocation]()
    }
    
}
