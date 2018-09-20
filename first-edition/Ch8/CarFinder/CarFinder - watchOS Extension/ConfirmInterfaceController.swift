//
//  ConfirmInterfaceController.swift
//  CarFinder
//
//  Created by Ahmed Bakir on 10/31/15.
//  Copyright © 2015 Ahmed Bakir. All rights reserved.
//

import WatchKit
import Foundation

protocol ConfirmDelegate {
    func saveLocation(note: String, address: String, time: NSTimeInterval)
}

class ConfirmInterfaceController: WKInterfaceController {
    
    @IBOutlet weak var coordinatesLabel: WKInterfaceLabel?
    @IBOutlet weak var noteLabel: WKInterfaceLabel?
    @IBOutlet weak var timeLabel: WKInterfaceLabel?
    
    var currentLocation : CLLocation?
    var delegate: ConfirmDelegate?
    var note: String = ""
    var address: String = ""
    
    var totalTime : NSTimeInterval = 0.0
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        if let inputDict = context as? Dictionary<String, AnyObject>{
            //
            
            if let inputDelegate = inputDict["Delegate"] as? ConfirmDelegate {
                delegate = inputDelegate
            }
            if let latitude = inputDict["Latitude"] as? Double {
                let longitude = inputDict["Longitude"] as! Double
                currentLocation = CLLocation(latitude: latitude, longitude: longitude)
                
                let formattedString = String(format: "%0.3f, %0.3f", latitude, longitude)
                coordinatesLabel?.setText(formattedString)
                
                let geocoder = CLGeocoder()
                
                geocoder.reverseGeocodeLocation(currentLocation!, completionHandler: { (placemarks: [CLPlacemark]?, error: NSError?) -> Void in
                    //sd
                    if error == nil {
                        if placemarks?.count > 0 {
                            let currentPlace = placemarks![0]
                            let placeString = "\(currentPlace.subThoroughfare!) \(currentPlace.thoroughfare!)"
                            
                            dispatch_async(dispatch_get_main_queue()) {
                                self.coordinatesLabel?.setText(placeString)
                                self.address = placeString
                            }
                        }
                    }
                })
            }
        }
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    @IBAction func confirm() {
        let noteString = self.note
        let addressString = self.address
        delegate?.saveLocation(noteString, address: addressString, time: self.totalTime * 60)
        dismissController()
    }
    
    @IBAction func cancel() {
        dismissController()
    }
    
    @IBAction func addNote() {
        let suggestionArray = ["On curb", "Next to house", "Next to lightpole"]
        presentTextInputControllerWithSuggestions(suggestionArray, allowedInputMode: WKTextInputMode.AllowEmoji) { (inputArray: [AnyObject]?) -> Void in
            if let inputStrings = inputArray as? [String] {
                if inputStrings.count > 0 {
                    let savedString = inputStrings[0]
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.noteLabel?.setText(savedString)
                        self.note = savedString
                    }
                    
                }
            }
        }
        
    }
    
    @IBAction func incrementTime() {
        dispatch_async(dispatch_get_main_queue()) {
            self.totalTime += 15
            
            let timeString = String(format: "%0.0f", self.totalTime)
            
            self.timeLabel?.setText("\(timeString) mins")
        }

    }

}
