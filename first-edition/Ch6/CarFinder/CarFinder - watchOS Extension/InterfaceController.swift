//
//  InterfaceController.swift
//  CarFinder - watchOS Extension
//
//  Created by Ahmed Bakir on 10/28/15.
//  Copyright © 2015 Ahmed Bakir. All rights reserved.
//

import WatchKit
import Foundation
import CoreLocation
import WatchConnectivity

class InterfaceController: WKInterfaceController, WCSessionDelegate {
    
    @IBOutlet weak var locationTable: WKInterfaceTable?
    
    var locations = [Dictionary<String, AnyObject>]()
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
        if (WCSession.isSupported()) {
            let session = WCSession.defaultSession()
            session.delegate = self
            session.activateSession()
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        //configureRows()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    //MARK - watch connectivity delegate
    func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        if let locationsArray = applicationContext["Locations"] as? [Dictionary<String, AnyObject>]{
            locations = locationsArray
            configureRows()
        }
        
    }
    
    //MARK - table delegate
    func configureRows() {
        
        locationTable?.setNumberOfRows(locations.count, withRowType: "LocationRowController")
        
        for var index = 0; index < locationTable?.numberOfRows; index++ {
            
            if let row = locationTable?.rowControllerAtIndex(index) as? LocationRowController {
                let location = locations[index]
                
                if let latitude = location["Latitude"] as? Double {
                    let longitude = location["Longitude"] as! Double
                    let formattedString = String(format: "%0.3f, %0.3f", latitude, longitude)
                    //row.coordinatesLabel?.setText("\(latitude), \(location["Longitude"]!)")
                    row.coordinatesLabel?.setText(formattedString)
                    
                }
                if let timeStamp = location["Timestamp"]  as? NSDate {
                    let dateFormatter = NSDateFormatter()
                    dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
                    dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
                    row.timeLabel?.setText(dateFormatter.stringFromDate(timeStamp))
                }
                
            }

        }

    }
    
    //MARK - row selection segue handler
    override func contextForSegueWithIdentifier(segueIdentifier: String, inTable table: WKInterfaceTable, rowIndex: Int) -> AnyObject? {
        
        if (segueIdentifier == "DetailSegue") {
            return locations[rowIndex]
        }
        
        return nil
    }
    
}
