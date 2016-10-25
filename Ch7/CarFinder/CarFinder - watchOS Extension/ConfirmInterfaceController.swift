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
    func saveLocation(note: String)
}

class ConfirmInterfaceController: WKInterfaceController {
    
    @IBOutlet weak var coordinatesLabel: WKInterfaceLabel?
    @IBOutlet weak var noteLabel: WKInterfaceLabel?
    
    var currentLocation : CLLocation?
    var delegate: ConfirmDelegate?
    var note = ""

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
        delegate?.saveLocation(self.note)
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
}
