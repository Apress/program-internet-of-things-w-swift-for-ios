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

class InterfaceController: WKInterfaceController, WCSessionDelegate, ConfirmDelegate {
    
    @IBOutlet weak var locationTable: WKInterfaceTable?
    
    var session : WCSession?
    
    var locations = [Dictionary<String, AnyObject>]()
    
    var currentLocation = CLLocation(latitude: 32.830579, longitude: -117.153839)
    
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
        if (WCSession.isSupported()) {
            session = WCSession.defaultSession()
            session?.delegate = self
            session?.activateSession()
        }
        
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        configureRows()
        
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
        
        self.locationTable?.setNumberOfRows(locations.count, withRowType: "LocationRowController")
        
        for var index = 0; index < locations.count; index++ {
            
            if let row = self.locationTable?.rowControllerAtIndex(index) as? LocationRowController {
                let location = self.locations[index]
                
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
        
        //self.locationTable?.setNumberOfRows(locations.count, withRowType: "LocationRowController")
    }
    
    //MARK - row selection segue handler
    override func contextForSegueWithIdentifier(segueIdentifier: String, inTable table: WKInterfaceTable, rowIndex: Int) -> AnyObject? {
        
        if (segueIdentifier == "DetailSegue") {
            return locations[rowIndex]
        }
        
        return nil
    }
    
    
    //MARK - Create View delegate
    
    func saveLocation(note :String) {
        //add a new record here
        let locationDict = ["Latitude" : currentLocation.coordinate.latitude , "Longitude" : currentLocation.coordinate.longitude, "Timestamp" : currentLocation.timestamp, "Note" : note]
        locations.insert(locationDict, atIndex: 0)
        
        session?.sendMessage(locationDict, replyHandler: nil, errorHandler: { (error: NSError) -> Void in
                print(error.description)
        })
        
    }
    
    //MARK - actions
    
    @IBAction func requestLocation() {
        
        let userDict = ["Latitude" : currentLocation.coordinate.latitude , "Longitude" : currentLocation.coordinate.longitude, "Delegate" : self]
        
        presentControllerWithName("ConfirmInterfaceController", context: userDict)
        
    }
    
    @IBAction func resetLocations() {
        //datasoruce = empty set
        locations = [Dictionary<String, AnyObject>]()
        
        configureRows()
    }
}
