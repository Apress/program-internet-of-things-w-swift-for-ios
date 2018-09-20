//
//  BeaconTransmitter.swift
//  iBeaconApp
//
//  Copyright (c) 2015 mdltorriente. All rights reserved.
//

import CoreBluetooth
import CoreLocation


protocol BeaconTransmitterDelegate: NSObjectProtocol {
    func didPowerOn()
    func didPowerOff()
    func onError(error: NSError)
}

class BeaconTransmitter: NSObject, CBPeripheralManagerDelegate {

    var peripheralManager: CBPeripheralManager!

    weak var delegate: BeaconTransmitterDelegate?
    
    var isAdvertising: Bool {
        get {
            return peripheralManager.isAdvertising
        }
    }
    
    init(delegate: BeaconTransmitterDelegate?) {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        self.delegate = delegate
    }
    
    func startAdvertising(beaconRegion: CLBeaconRegion?, power:NSNumber?) {
        let data = NSDictionary(dictionary: (beaconRegion?.peripheralDataWithMeasuredPower(power))!) as! [String: AnyObject]
        peripheralManager.startAdvertising(data)
    }
    
    func stopAdvertising() {
        peripheralManager.stopAdvertising()
    }
    
    // MARK: CBPeriperalManagerDelegate methods
    
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        
        switch (peripheral.state) {
        case .PoweredOn:
            print("Peripheral Manager powered on.")
            delegate?.didPowerOn()

        case .PoweredOff:
            print("Peripheral Manager powered off.")
            if (isAdvertising) {
                stopAdvertising()
            }
            delegate?.didPowerOff()

        default:
            print("Peripheral Manager state changed: \(peripheral.state)")
        }
    }
}