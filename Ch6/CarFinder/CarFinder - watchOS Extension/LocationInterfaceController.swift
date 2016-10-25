//
//  LocationInterfaceController.swift
//  CarFinder
//
//  Created by Ahmed Bakir on 10/28/15.
//  Copyright © 2015 Ahmed Bakir. All rights reserved.
//

import WatchKit
import Foundation


class LocationInterfaceController: WKInterfaceController {

    @IBOutlet weak var locationMap: WKInterfaceMap?
    @IBOutlet weak var coordinatesLabel: WKInterfaceLabel?
    @IBOutlet weak var timeLabel: WKInterfaceLabel?
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
        
        
        // Configure interface objects here.
        if let locationDict = context as? Dictionary<String, AnyObject> {
            
            if let latitude = locationDict["Latitude"] as? Double {
                
                if let longitude = locationDict["Longitude"] as? Double {
                    let location = CLLocation(latitude: latitude, longitude: longitude)
                    
                    let prettyLocation = String(format: "%.2f, %.2f", location.coordinate.latitude, location.coordinate.longitude       )
                    
                    
                    coordinatesLabel?.setText(prettyLocation)
                    
                    locationMap?.addAnnotation(location.coordinate, withPinColor: WKInterfaceMapPinColor.Red)
                    
                    let mapRegion = MKCoordinateRegionMake(location.coordinate, MKCoordinateSpanMake(0.1, 0.1))
                    
                    locationMap?.setRegion(mapRegion)
                }
                
            }
            
            if let timestamp = locationDict["Timestamp"] as? NSDate  {
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
                dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
                let prettyTime = dateFormatter.stringFromDate(timestamp)
                timeLabel?.setText(prettyTime)
            }
            
        }
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
