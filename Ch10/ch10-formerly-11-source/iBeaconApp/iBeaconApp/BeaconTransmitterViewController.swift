//
//  BeaconTransmitterViewController.swift
//  iBeaconApp
//
//  Copyright (c) 2015 mdltorriente. All rights reserved.
//

import UIKit
import CoreLocation


class BeaconTransmitterViewController: UIViewController, UITextFieldDelegate, BeaconTransmitterDelegate {
    
    let kUUIDKey = "transmit-proximityUUID"
    let kMajorIdKey = "transmit-majorId"
    let kMinorIdKey = "transmit-minorId"
    let kPowerKey = "transmit-measuredPower"
    
    @IBOutlet weak var advertiseSwitch: UISwitch!
    @IBOutlet weak var generateUUIDButton: UIButton!
    @IBOutlet weak var uuidTextField: UITextField!
    @IBOutlet weak var majorTextField: UITextField!
    @IBOutlet weak var minorTextField: UITextField!
    @IBOutlet weak var powerTextField: UITextField!
    @IBOutlet weak var helpTextView: UITextView!
    
    var doneButton: UIBarButtonItem!
    var beaconTransmitter: BeaconTransmitter!
    var isBluetoothPowerOn: Bool = false
    
    let numberFormatter = NSNumberFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        beaconTransmitter = BeaconTransmitter(delegate: self)
        
        doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Done, target: self, action: "dismissKeyboard")

        numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
        
        uuidTextField.delegate = self
        majorTextField.delegate = self
        minorTextField.delegate = self
        powerTextField.delegate = self
        helpTextView.text = ""
        advertiseSwitch.setOn(false, animated: true)
        
        initFromDefaultValues()
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    private func initFromDefaultValues() {
        let defaults = NSUserDefaults.standardUserDefaults()
        
        if let uuid = defaults.stringForKey(kUUIDKey) {
            uuidTextField.text = uuid
        }
        if let major = defaults.stringForKey(kMajorIdKey) {
            majorTextField.text = major
        }
        if let minor = defaults.stringForKey(kMinorIdKey) {
            minorTextField.text = minor
        }
        if let power = defaults.stringForKey(kPowerKey) {
            powerTextField.text = power
        }
    }
    
    private func canBeginAdvertise() -> Bool {
        if !isBluetoothPowerOn {
            showAlert("You must have Bluetooth powered on to advertise!")
            return false
        }
        if uuidTextField.text!.isEmpty || majorTextField.text!.isEmpty
            || minorTextField.text!.isEmpty || powerTextField.text!.isEmpty {
                showAlert("You must complete all fields")
            return false
        }
        return true
    }

    private func showAlert(message: String) {
        let alertController = UIAlertController(title: "iBeaconApp", message: message, preferredStyle: .Alert)
        
        alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    @IBAction func generateUUID() {
        uuidTextField.text = NSUUID().UUIDString
    }
    
    @IBAction func toggleAdvertising() {
        if advertiseSwitch.on {
            dismissKeyboard()
            if !canBeginAdvertise() {
                advertiseSwitch.setOn(false, animated: true)
                return
            }
            let uuid = NSUUID(UUIDString: uuidTextField.text!)
            let identifier = "my.beacon"
            var beaconRegion: CLBeaconRegion?
            
            if let major = Int(majorTextField.text!) {
                if let minor = Int(minorTextField.text!) {
                    beaconRegion = CLBeaconRegion(proximityUUID: uuid!, major: CLBeaconMajorValue(major), minor: CLBeaconMinorValue(minor), identifier: identifier)
                } else {
                    beaconRegion = CLBeaconRegion(proximityUUID: uuid!, major: CLBeaconMajorValue(major), identifier: identifier)
                }
            } else {
                beaconRegion = CLBeaconRegion(proximityUUID: uuid!, identifier: identifier)
            }
            
            beaconRegion!.notifyEntryStateOnDisplay = true
            beaconRegion!.notifyOnEntry = true
            beaconRegion!.notifyOnExit = true
            
            let power = numberFormatter.numberFromString(powerTextField.text!)
            
            beaconTransmitter.startAdvertising(beaconRegion, power: power)
        } else {
            beaconTransmitter.stopAdvertising()
        }
    }
    
    func dismissKeyboard() {
        uuidTextField.resignFirstResponder()
        majorTextField.resignFirstResponder()
        minorTextField.resignFirstResponder()
        powerTextField.resignFirstResponder()
        navigationItem.rightBarButtonItem = nil
    }
    
    // MARK: UITextFieldDelegate methods
    
    func textFieldDidBeginEditing(textField: UITextField) {
        navigationItem.rightBarButtonItem = doneButton
        advertiseSwitch.setOn(false, animated: true)

        if textField == uuidTextField {
            helpTextView.text = NSLocalizedString("transmit.help.proximityUUID", comment:"foo")
        }
        else if textField == majorTextField {
            helpTextView.text = NSLocalizedString("transmit.help.major", comment:"foo")
        }
        else if textField == minorTextField {
            helpTextView.text = NSLocalizedString("transmit.help.minor", comment:"foo")
        }
        else if textField == powerTextField {
            helpTextView.text = NSLocalizedString("transmit.help.measuredPower", comment:"foo")
        }
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        helpTextView.text = ""
        
        let defaults = NSUserDefaults.standardUserDefaults()
        
        if textField == uuidTextField && !textField.text!.isEmpty {
            defaults.setObject(textField.text, forKey: kUUIDKey)
        }
        else if textField == majorTextField && !textField.text!.isEmpty {
            defaults.setObject(textField.text, forKey: kMajorIdKey)
        }
        else if textField == minorTextField && !textField.text!.isEmpty {
            defaults.setObject(textField.text, forKey: kMinorIdKey)
        }
        else if textField == powerTextField && !textField.text!.isEmpty {
            // power values are typically negative
            let value = numberFormatter.numberFromString(powerTextField.text!)
            if (value?.intValue > 0) {
                powerTextField.text = numberFormatter.stringFromNumber(0 - value!.intValue)
            }
            defaults.setObject(textField.text, forKey: kPowerKey)
        }
    }
    
    // MARK: BeaconTransmitterDelegate methods
    
    func didPowerOn() {
        isBluetoothPowerOn = true
    }
    
    func didPowerOff() {
        isBluetoothPowerOn = false
    }
    
    func onError(error: NSError) {
        
    }
}
