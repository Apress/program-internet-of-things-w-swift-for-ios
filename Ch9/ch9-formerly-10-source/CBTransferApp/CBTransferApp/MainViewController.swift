//
//  ViewController.swift
//  CBTransferApp
//
//  Copyright (c) 2015 mdltorriente. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate {

    @IBOutlet weak var bluetoothStateLabel: UILabel!

    var centralManager: CBCentralManager!
    var isBluetoothPoweredOn: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier == kCentralRoleSegue || identifier == kPeripheralRoleSegue {
            if !isBluetoothPoweredOn {
                showAlertForSettings()
                return false;
            }
        }
        return true
    }

    func showAlertForSettings() {
        let alertController = UIAlertController(title: "CBTransferApp", message: "Turn On Bluetooth to Connect to Peripherals", preferredStyle: .Alert)
        
        let cancelAction = UIAlertAction(title: "Settings", style: .Cancel) { (action) in
            let url = NSURL(string: UIApplicationOpenSettingsURLString)
            UIApplication.sharedApplication().openURL(url!)
        }
        alertController.addAction(cancelAction)
        
        let okAction = UIAlertAction(title: "OK", style: .Default) { (action) in
            // do nothing
        }
        alertController.addAction(okAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }

    // MARK: CBCentralManager methods

    func centralManagerDidUpdateState(central: CBCentralManager) {
        switch (central.state) {
        case .PoweredOn:
            isBluetoothPoweredOn = true;
            bluetoothStateLabel.text = "Bluetooth ON"
            bluetoothStateLabel.textColor = UIColor.greenColor()
            break
        case .PoweredOff:
            isBluetoothPoweredOn = false
            bluetoothStateLabel.text = "Bluetooth OFF"
            bluetoothStateLabel.textColor = UIColor.redColor()
            break
        default:
            break;
        }
    }

}

