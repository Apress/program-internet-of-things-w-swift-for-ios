//
//  RegionMonitorViewController.swift
//  iBeaconApp
//
//  Copyright (c) 2015 mdltorriente. All rights reserved.
//

import UIKit
import CoreLocation

extension UIView {

    func rotate(fromValue: CGFloat, toValue: CGFloat, duration: CFTimeInterval = 1.0, completionDelegate: AnyObject? = nil) {

        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = fromValue
        rotateAnimation.toValue = toValue
        rotateAnimation.duration = duration

        if let delegate: AnyObject = completionDelegate {
            rotateAnimation.delegate = delegate
        }
        self.layer.addAnimation(rotateAnimation, forKey: nil)
    }
}

class RegionMonitorViewController: UIViewController, UITextFieldDelegate, RegionMonitorDelegate {

    let kUUIDKey = "monitor-proximityUUID"
    let kMajorIdKey = "monitor-transmit-majorId"
    let kMinorIdKey = "monitor-transmit-minorId"

    let uuidDefault = "2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6"

    @IBOutlet weak var regionIdLabel: UILabel!
    @IBOutlet weak var uuidTextField: UITextField!
    @IBOutlet weak var majorTextField: UITextField!
    @IBOutlet weak var minorTextField: UITextField!
    @IBOutlet weak var proximityLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
    @IBOutlet weak var monitorButton: UIButton!

    var doneButton: UIBarButtonItem!
    var regionMonitor: RegionMonitor!
    var isMonitoring: Bool = false

    let distanceFormatter = NSLengthFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()
        regionMonitor = RegionMonitor(delegate: self)

        doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Done, target: self, action: "dismissKeyboard")

        regionIdLabel.text = ""
        uuidTextField.text = ""
        uuidTextField.delegate = self
        majorTextField.text = ""
        majorTextField.delegate = self
        minorTextField.text = ""
        minorTextField.delegate = self
        proximityLabel.text = ""
        distanceLabel.text = ""
        rssiLabel.text = ""

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
    }

    override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        if isMonitoring == true {
            // if still scanning, restart the animation
            monitorButton.rotate(0.0, toValue: CGFloat(M_PI * 2), completionDelegate: self)
        }
    }

    @IBAction func toggleMonitoring() {
        if isMonitoring {
            regionMonitor.stopMonitoring()
        } else {
            if uuidTextField.text!.isEmpty {
                showAlert("Please provide a valid UUID")
                return
            }

            regionIdLabel.text = ""
            proximityLabel.text = ""
            distanceLabel.text = ""
            rssiLabel.text = ""


            if let uuid = NSUUID(UUIDString: uuidTextField.text!) {
                let identifier = "my.beacon"

                var beaconRegion: CLBeaconRegion?

                if let major = Int(majorTextField.text!) {
                    if let minor = Int(minorTextField.text!) {
                        beaconRegion = CLBeaconRegion(proximityUUID: uuid, major: CLBeaconMajorValue(major), minor: CLBeaconMinorValue(minor), identifier: identifier)
                    } else {
                        beaconRegion = CLBeaconRegion(proximityUUID: uuid, major: CLBeaconMajorValue(major), identifier: identifier)
                    }
                } else {
                    beaconRegion = CLBeaconRegion(proximityUUID: uuid, identifier: identifier)
                }

                // later, these values can be set from the UI
                beaconRegion!.notifyEntryStateOnDisplay = true
                beaconRegion!.notifyOnEntry = true
                beaconRegion!.notifyOnExit = true

                regionMonitor.startMonitoring(beaconRegion)
            } else {
                let alertController = UIAlertController(title:"iBeaconApp", message: "Please enter a valid UUID", preferredStyle: .Alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                self.presentViewController(alertController, animated: true, completion: nil)
            }
        }
    }

    func dismissKeyboard() {
        uuidTextField.resignFirstResponder()
        majorTextField.resignFirstResponder()
        minorTextField.resignFirstResponder()
        navigationItem.rightBarButtonItem = nil
    }

    private func showAlert(message: String) {
        let alertController = UIAlertController(title: "iBeaconApp", message: message, preferredStyle: .Alert)

        alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))

        presentViewController(alertController, animated: true, completion: nil)
    }

    // MARK: UITextFieldDelegate methods

    func textFieldDidBeginEditing(textField: UITextField) {
        navigationItem.rightBarButtonItem = doneButton
    }

    func textFieldDidEndEditing(textField: UITextField) {

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
    }

    // MARK: RegionMonitorDelegate methods

    func onBackgroundLocationAccessDisabled() {
        let alertController = UIAlertController(
            title: NSLocalizedString("regmon.alert.title.location-access-disabled", comment: "foo"),
            message: NSLocalizedString("regmon.alert.message.location-access-disabled", comment: "foo"),
            preferredStyle: .Alert)

        alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))

        alertController.addAction(
            UIAlertAction(title: "Settings", style: .Default) { (action) in
                if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
                    UIApplication.sharedApplication().openURL(url)
                }
            })
        self.presentViewController(alertController, animated: true, completion: nil)
    }

    func didStartMonitoring() {
        isMonitoring = true
        monitorButton.rotate(0.0, toValue: CGFloat(M_PI * 2), completionDelegate: self)
    }

    func didStopMonitoring() {
        isMonitoring = false
    }

    func didEnterRegion(region: CLRegion!) {

    }

    func didExitRegion(region: CLRegion!) {

    }

    func didRangeBeacon(beacon: CLBeacon!, region: CLRegion!) {
        regionIdLabel.text = region.identifier
        uuidTextField.text = beacon.proximityUUID.UUIDString
        majorTextField.text = "\(beacon.major)"
        minorTextField.text = "\(beacon.minor)"

        switch (beacon.proximity) {
        case CLProximity.Far:
            proximityLabel.text = "Far"
        case CLProximity.Near:
            proximityLabel.text = "Near"
        case CLProximity.Immediate:
            proximityLabel.text = "Immediate"
        case CLProximity.Unknown:
            proximityLabel.text = "unknown"
        }

        distanceLabel.text = distanceFormatter.stringFromMeters(beacon.accuracy)
        
        rssiLabel.text = "\(beacon.rssi)"
    }
    
    func onError(error: NSError) {
        
    }
}
