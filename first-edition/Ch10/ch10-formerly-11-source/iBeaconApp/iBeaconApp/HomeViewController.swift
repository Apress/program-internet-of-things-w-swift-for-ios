//
//  HomeViewController.swift
//  iBeaconApp
//
//  Copyright (c) 2015 mdltorriente. All rights reserved.
//

import UIKit
import CoreBluetooth

class HomeViewController: UIViewController, CBCentralManagerDelegate {

    @IBOutlet weak var bluetoothStateLabel: UILabel!

    var centralManager: CBCentralManager!
    var isBluetoothPoweredOn: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func centralManagerDidUpdateState(central: CBCentralManager) {
        switch (central.state) {
        case .PoweredOn:
            isBluetoothPoweredOn = true
            bluetoothStateLabel.text = "Bluetooth ON"
            bluetoothStateLabel.textColor = UIColor.greenColor()
        case .PoweredOff:
            isBluetoothPoweredOn = false
            bluetoothStateLabel.text = "Bluetooth OFF"
            bluetoothStateLabel.textColor = UIColor.redColor()
        default:
            break
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier == "RegionMonitorSegue" || identifier == "iBeaconSegue" || identifier == "ConfigureSegue" {
            if !isBluetoothPoweredOn {
                showAlertForSettings()
                return false;
            }
        }
        return true
    }
    
    private func showAlertForSettings() {
        let alertController = UIAlertController(title: "iBeacon App", message: "Turn On Bluetooth!", preferredStyle: .Alert)
        
        let cancelAction = UIAlertAction(title: "Settings", style: .Cancel) { (action) in
            if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
                UIApplication.sharedApplication().openURL(url)
            }
        }
        alertController.addAction(cancelAction)
        
        let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alertController.addAction(okAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
}

