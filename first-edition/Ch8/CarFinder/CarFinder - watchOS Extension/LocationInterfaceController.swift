//
//  LocationInterfaceController.swift
//  CarFinder
//
//  Created by Ahmed Bakir on 10/28/15.
//  Copyright © 2015 Ahmed Bakir. All rights reserved.
//

import WatchKit
import Foundation
import CoreLocation

class LocationInterfaceController: WKInterfaceController {

    @IBOutlet weak var locationMap: WKInterfaceMap?
    @IBOutlet weak var coordinatesLabel: WKInterfaceLabel?
    @IBOutlet weak var timeLabel: WKInterfaceLabel?
    @IBOutlet weak var weatherLabel: WKInterfaceLabel?
    
    var currentLocation : CLLocation?
    
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
                    
                    currentLocation = CLLocation(latitude: latitude, longitude: longitude)
                    
                    locationMap?.addAnnotation(location.coordinate, withPinColor: WKInterfaceMapPinColor.Red)
                    
                    let mapRegion = MKCoordinateRegionMake(location.coordinate, MKCoordinateSpanMake(0.1, 0.1))
                    
                    locationMap?.setRegion(mapRegion)
                    
                    geocodeLocation()
                    
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
    
    func geocodeLocation() {
        
        if currentLocation != nil {
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(currentLocation!, completionHandler: { (placemarks: [CLPlacemark]?, error: NSError?) -> Void in
                //sd
                if error == nil {
                    if placemarks?.count > 0 {
                       
                        let currentPlace = placemarks![0]
                        let placeString = "\(currentPlace.subThoroughfare!) \(currentPlace.thoroughfare!)"
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            self.coordinatesLabel?.setText(placeString)
                        }
                        
                        let zipCode = currentPlace.postalCode!
                        self.retrieveWeather(zipCode)
                        
                    }
                } else {
                    print(error?.description)
                }
            })
        }
    

    }
    
    func retrieveWeather(zipCode: String) {
        
        let apiKey = "748504be0ff02aa3"
        
        let urlString = "https://api.wunderground.com/api/\(apiKey)/conditions/q/\(zipCode).json"
        
        let url = NSURL(string: urlString)
        let session = NSURLSession.sharedSession()
        let urlTask = session.dataTaskWithURL(url!, completionHandler: { (responseData: NSData?, response: NSURLResponse?,error:NSError?) -> Void in
            if error == nil {
                do {
                    let jsonDict = try NSJSONSerialization.JSONObjectWithData(responseData!, options: NSJSONReadingOptions.AllowFragments)

                    if let resultsDict = jsonDict["current_observation"] as? Dictionary<String, AnyObject> {
                        if let tempF = resultsDict["temp_f"] as? Double {
                            self.weatherLabel?.setText("\(tempF) F")
                        }
                    }
                } catch {
                    print("error: invalid json data")
                }
                
            } else {
                print(error?.description)
            }
        })
        urlTask.resume()
    }
}