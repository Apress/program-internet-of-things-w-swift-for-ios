//
//  BluetoothService.swift
//  IOTHome
//
//  Created by Ahmed Bakir on 2018/02/20.
//  Copyright © 2018 Ahmed Bakir. All rights reserved.
//

import Foundation
import CoreBluetooth

let doorServiceUUID = CBUUID(string: "83b46845-6e9c-4b25-89cf-871cc74cc68e")
let battServiceUUID = CBUUID(string: "7d6925f3-6e19-48c6-a503-05585abe761e")
let doorCharUUID = CBUUID(string: "4b61d6b9-2e29-4fdf-a74a-7b8bf70ecd9a")
let battCharUUID = CBUUID(string: "8e628af6-0275-4f80-bb64-58f2b2771cba")

enum ConnectionStatus {
    case unknown
    case scanning
    case connecting
    case connected
    case disconnected
}

struct BluetoothDevice : Codable {
    var name: String
    var uuid : String
}

typealias BluetoothDevices = [BluetoothDevice]

protocol BluetoothServiceDelegate : class {
    func didUpdateConnection(status: ConnectionStatus)
    func didReceiveDoorUpdate(value: String)
    func didReceiveBatteryUpdate(value: String)
}

class BluetoothService : NSObject {
    
    let doorServices = [doorServiceUUID]
    let doorCharacteristics = [doorCharUUID, battCharUUID]
    
    //static let sharedInstance = BluetoothManager()
    var centralManager : CBCentralManager?
    var knownDevices = [BluetoothDevice]()
    
    var connectedPeripheral : CBPeripheral?
    var connectionStatus = ConnectionStatus.unknown
    
    weak var delegate : BluetoothServiceDelegate?
    
    convenience init(delegate : BluetoothServiceDelegate) {
        self.init()
        self.delegate = delegate
    }
    
    private override init() {
        super.init()
        loadFromPlist()
        centralManager = CBCentralManager.init(delegate: self, queue: nil)
    }
    
    // MARK:- Bluetooth Operations
    
    func isAuthorized() -> Bool {
        return CBPeripheralManager.authorizationStatus() == .authorized
    }
    
    func connect() {
        switch connectionStatus {
        case .unknown, .disconnected :
            centralManager?.scanForPeripherals(withServices: nil, options: nil)
            connectionStatus = .scanning
        case .connected, .connecting:
            if let connectedPeripheral = connectedPeripheral {
                centralManager?.cancelPeripheralConnection(connectedPeripheral)
                connectionStatus = .disconnected
            }
        default:
            centralManager?.stopScan()
            connectionStatus = .disconnected
        }
        delegate?.didUpdateConnection(status: connectionStatus)
    }
    
    // MARK:- File manager
    func documentsDirectoryUrl() -> URL? {
        let fileManager = FileManager.default
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    private var deviceListFileUrl : URL? {
        guard let documentsUrl = documentsDirectoryUrl() else {
            return nil
        }
        
        return documentsUrl.appendingPathComponent("BluetoothDevices.plist")
    }
    
    func loadFromPlist() {
        
        knownDevices = [BluetoothDevice]()
        
        guard let fileUrl = deviceListFileUrl else {
            return
        }
        
        do {
            let deviceListData = try Data(contentsOf: fileUrl)
            let decoder = PropertyListDecoder()
            knownDevices = try decoder.decode(BluetoothDevices.self, from: deviceListData)
        } catch {
            NSLog("Error reading plist")
        }
    }
    
    func saveToPlist() {
        guard let fileUrl = deviceListFileUrl else {
            return
        }
        
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        do {
            let deviceListData = try encoder.encode(knownDevices)
            try deviceListData.write(to: fileUrl)
        } catch {
            NSLog("Error writing plist")
        }
        
    }
}

extension BluetoothService : CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch(central.state) {
        case .poweredOn:
            NSLog("It's showtime")
        default:
            NSLog("Device is not ready")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        //
        NSLog("name: \(String(describing: peripheral.name))\n services: \(String(describing: peripheral.services?.description))\n \(advertisementData.description)\n\n")
        
        if peripheral.name == "IOTDoor" {
            self.connectedPeripheral = peripheral
            self.connectedPeripheral?.delegate = self
            centralManager?.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        central.stopScan()
        self.connectedPeripheral?.discoverServices(doorServices)
        
        self.connectionStatus = .connecting
        delegate?.didUpdateConnection(status: connectionStatus)
    }
}

extension BluetoothService : CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            return
        }
        for service in services {
            //peripheral.discoverCharacteristics(doorCharacteristics, for: service)
//            if service.uuid == battServiceUUID {
//                peripheral.discoverCharacteristics([battCharUUID], for: service)
//            }
//            if service.uuid == doorServiceUUID {
//                peripheral.discoverCharacteristics([doorCharUUID], for: service)
//            }
            peripheral.discoverCharacteristics(doorCharacteristics, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        guard let characteristics = service.characteristics else {
            return
        }
        for characteristic in characteristics {
            if characteristic.uuid == doorCharUUID {
                self.connectedPeripheral?.setNotifyValue(true, for: characteristic)
            }
            
            if characteristic.uuid == battCharUUID {
                self.connectedPeripheral?.setNotifyValue(true, for: characteristic)
            }
        }
        self.connectionStatus = .connected
        delegate?.didUpdateConnection(status: connectionStatus)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let characteristicData = characteristic.value else {
            return
        }
        if characteristic.uuid == doorCharUUID, let stringValue = String(data: characteristicData, encoding: String.Encoding.utf8) {
            delegate?.didReceiveDoorUpdate(value: stringValue)
            
        }
        
        if characteristic.uuid == battCharUUID, let stringValue = String(data: characteristicData, encoding: String.Encoding.utf8) {
            delegate?.didReceiveBatteryUpdate(value: stringValue)
        }
    }
}
