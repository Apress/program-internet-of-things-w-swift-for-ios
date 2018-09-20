//
//  TransferService.swift
//  CBTransferApp
//
//  Copyright (c) 2015 mdltorriente. All rights reserved.
//

import CoreBluetooth

protocol TransferServiceDelegate: NSObjectProtocol {
    func didPowerOn()
    func didPowerOff()
    func getDataToSend() -> NSData
}

class TransferService: NSObject, CBPeripheralManagerDelegate {
    
    var peripheralManager: CBPeripheralManager!
    var transferCharacteristic: CBMutableCharacteristic!
    var dataToSend: NSData?
    var sendDataIndex: Int?
    
    var isAdvertising: Bool {
        get {
            return peripheralManager.isAdvertising
        }
    }
    
    weak var delegate: TransferServiceDelegate?
    
    init(delegate: TransferServiceDelegate?) {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        self.delegate = delegate
    }
    
    // MARK: CBPeriperalManagerDelegate methods
    
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        
        switch (peripheral.state) {
        case .PoweredOn:
            print("Peripheral Manager powered on.")
            setupServices()
            delegate?.didPowerOn()
            break
            
        case .PoweredOff:
            print("Peripheral Manager powered off.")
            if (isAdvertising) {
                stopAdvertising()
            }
            teardownServices()
            delegate?.didPowerOff()
            break
            
        default:
            print("Peripheral Manager state changed: \(peripheral.state)")
            break
        }
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, didAddService service: CBService, error: NSError?) {
        print("didAddService: \(service) with error: \(error)")
    }
    
    func peripheralManagerDidStartAdvertising(peripheral: CBPeripheralManager, error: NSError?) {
        print("peripheralManagerDidStartAdvertising with error: \(error)")
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didSubscribeToCharacteristic characteristic: CBCharacteristic) {
        print("didSubscribeToCharacteristic")
        
        dataToSend = delegate?.getDataToSend()
        sendDataIndex = 0
        sendData()
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFromCharacteristic characteristic: CBCharacteristic) {
        print("didUnsubscribeFromCharacteristic")
    }
    
    func startAdvertising() {
        print("Start advertising")
        
        let cbuuidService = CBUUID(string: kTransferServiceUUID)
        
        let services = [cbuuidService]
        
        let advertisingDict = Dictionary(dictionaryLiteral: (CBAdvertisementDataServiceUUIDsKey, services))
        
        peripheralManager.startAdvertising(advertisingDict)
    }
    
    func stopAdvertising() {
        print("Stop advertising")
        
        peripheralManager.stopAdvertising()
    }
    
    private func setupServices() {
        
        let cbuuidCharacteristic = CBUUID(string: kTransferCharacteristicUUID)
        
        transferCharacteristic = CBMutableCharacteristic(type: cbuuidCharacteristic, properties: CBCharacteristicProperties.Notify, value: nil, permissions: CBAttributePermissions.Readable)
        
        let cbuuidService = CBUUID(string: kTransferServiceUUID)
        
        let transferService = CBMutableService(type: cbuuidService, primary: true)
        transferService.characteristics = [transferCharacteristic]
        
        peripheralManager.addService(transferService)
    }
    
    private func teardownServices() {
        peripheralManager.removeAllServices()
    }
    
    private func sendData() {
        print("sendData")
        
        let MTU = 20
        
        struct eom { static var pending = false }
        
        func sendEOM() -> Bool {
            eom.pending = true
            let data =  ("EOM" as NSString).dataUsingEncoding(NSUTF8StringEncoding)
            print("sending \(data)")
            if peripheralManager.updateValue(data!, forCharacteristic: transferCharacteristic, onSubscribedCentrals: nil) {
                eom.pending = false;
            }
            return !eom.pending
        }

        if eom.pending {
            if sendEOM() { return }
        }
        
        if sendDataIndex >= dataToSend?.length {
            return
        }
        
        var didSend = true
        while didSend {
            var amountToSend = dataToSend!.length - sendDataIndex!
            print("amountToSend is \(amountToSend)")
            if (amountToSend > MTU) {
                amountToSend = MTU
            }
            let chunk = NSData(bytes: dataToSend!.bytes+sendDataIndex!, length: amountToSend)
            didSend = peripheralManager.updateValue(chunk, forCharacteristic: transferCharacteristic, onSubscribedCentrals: nil)
            if !didSend {
                return
            }
            print("didSend \(chunk)")
            
            sendDataIndex! += amountToSend
            if sendDataIndex >= dataToSend?.length {
                sendEOM()
                return
            }
        }
    }
    
    func peripheralManagerIsReadyToUpdateSubscribers(peripheral: CBPeripheralManager) {
        sendData()
    }
}