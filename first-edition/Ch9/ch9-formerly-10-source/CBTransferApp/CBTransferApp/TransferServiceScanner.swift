//
//  TransferServiceScanner.swift
//  CBTransferApp
//
//  Copyright (c) 2015 mdltorriente. All rights reserved.
//

import CoreBluetooth

protocol TransferServiceScannerDelegate: NSObjectProtocol {
    func didStartScan()
    func didStopScan()
    func didTransferData(data: NSData?)
}

class TransferServiceScanner: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    var centralManager: CBCentralManager!
    var discoveredPeripheral: CBPeripheral?
    var data: NSMutableData = NSMutableData()

    weak var delegate: TransferServiceScannerDelegate?

    init(delegate: TransferServiceScannerDelegate?) {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        self.delegate = delegate
    }
    
    func startScan() {
        print("Start scan")
        let services = [CBUUID(string: kTransferServiceUUID)]
        let options = Dictionary(dictionaryLiteral: (CBCentralManagerScanOptionAllowDuplicatesKey, false))
        centralManager.scanForPeripheralsWithServices(services, options: options)
        delegate?.didStartScan()
    }

    func stopScan() {
        print("Stop scan")
        centralManager.stopScan()
        delegate?.didStopScan()
    }

    // MARK: CBCentralManagerDelegate methods

    func centralManagerDidUpdateState(central: CBCentralManager) {

        switch (central.state) {
        case .PoweredOn:
            print("Central Manager powered on.")
            break

        case .PoweredOff:
            print("Central Manager powered off.")
            stopScan()
            break;

        default:
            print("Central Manager changed state \(central.state)")
            break
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        print("didDiscoverPeripheral \(peripheral)")
        
        // reject if above reasonable range, or too low
        if (RSSI.integerValue > -15) || (RSSI.integerValue < -35) {
            print("not in range, RSSI is \(RSSI.integerValue)")
            return;
        }
        
        if (discoveredPeripheral != peripheral) {
            discoveredPeripheral = peripheral
            
            print("connecting to peripheral \(peripheral)")
            centralManager.connectPeripheral(peripheral, options: nil)
        }
    }

    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("didConnectPeripheral")
        stopScan()
        data.length = 0
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: kTransferServiceUUID)])
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("didDisconnectPeripheral")
        discoveredPeripheral = nil
    }

    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("didFailToConnectPeripheral")
    }

    // MARK: CBPeripheralDelegate methods

    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        print("didDiscoverServices")
        
        if (error != nil) {
            print("Encountered error: \(error!.localizedDescription)")
            return
        }
        
        // look for the characteristics we want
        for service in peripheral.services! {
            peripheral.discoverCharacteristics([CBUUID(string: kTransferCharacteristicUUID)], forService: service)
        }
    }

    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        print("didDiscoverCharacteristicsForService")

        if (error != nil) {
            print("Encountered error: \(error!.localizedDescription)")
            return
        }

        // loop through and verify the characteristic is the correct one, then subscribe to it
        let cbuuid = CBUUID(string: kTransferCharacteristicUUID)
        for characteristic in service.characteristics! {
            print("characteristic.UUID is \(characteristic.UUID)")
            if characteristic.UUID == cbuuid {
                peripheral.setNotifyValue(true, forCharacteristic: characteristic)
            }
        }
    }

    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        print("didUpdateValueForCharacteristic")

        if (error != nil) {
            print("Encountered error: \(error!.localizedDescription)")
            return
        }

        let stringFromData = NSString(data: characteristic.value!, encoding: NSUTF8StringEncoding)
        print("received \(stringFromData)")
        
        if stringFromData == "EOM" {
            // data transfer is complete, so notify delegate
            delegate?.didTransferData(data)

            // unsubscribe from characteristic
            peripheral.setNotifyValue(false, forCharacteristic: characteristic)

            // disconnect from peripheral
            centralManager.cancelPeripheralConnection(peripheral)
        }
        
        data.appendData(characteristic.value!)
    }

    func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        print("didUpdateNotificationStateForCharacteristic")

        if (error != nil) {
            print("Encountered error: \(error!.localizedDescription)")
            return
        }

        if characteristic.UUID != CBUUID(string: kTransferCharacteristicUUID) {
            return
        }

        if characteristic.isNotifying {
            print("notification started for \(characteristic)")
        } else {
            print("notification stopped for \(characteristic), disconnecting...")
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
}