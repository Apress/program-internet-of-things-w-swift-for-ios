//
//  ServicesViewController.swift
//  HomeKitApp
//
//  Copyright © 2015 mdltorriente. All rights reserved.
//

import UIKit
import HomeKit


class ServicesViewController: UITableViewController, HMAccessoryDelegate {

    struct Identifiers {
        static let CharacteristicCell = "CharacteristicCell"
        static let PowerStateCell = "PowerStateCell"
        static let SliderCell = "SliderCell"
        static let SegmentedCell = "SegmentedCell"
    }

    var accessory: HMAccessory? {
        didSet {
            accessory?.delegate = self
        }
    }
    var services = [HMService]()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "\(accessory!.name) Services"
        configureServices()
        enableNotifications(true)
    }

    private func configureServices() {

        printServicesForAccessory(accessory!)

        for service in accessory!.services as [HMService] {
            if service.serviceType == HMServiceTypeAccessoryInformation {
                services.insert(service, atIndex: 0)
            } else {
                services.append(service)
            }
        }
    }

    private func enableNotifications(enable: Bool) {
        for service in services {
            for characteristic in service.characteristics {
                if characteristic.properties.contains(HMCharacteristicPropertySupportsEventNotification) {
                    characteristic.enableNotification(enable, completionHandler: { error in
                        if let error = error {
                            print("Failed to enable notifications for \(characteristic): \(error.localizedDescription)")
                        }
                    })
                }
            }
        }
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        enableNotifications(false)
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return services.count
    }

    // MARK: UITableViewController methods

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return services[section].characteristics.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        var reuseIdentifier = Identifiers.CharacteristicCell

        let characteristic = services[indexPath.section].characteristics[indexPath.row]

        if characteristic.isReadOnly || characteristic.isWriteOnly {
            reuseIdentifier = Identifiers.CharacteristicCell
        } else if characteristic.isBoolean {
            reuseIdentifier = Identifiers.PowerStateCell
        } else if characteristic.hasValueDescriptions {
            reuseIdentifier = Identifiers.SegmentedCell
        } else if characteristic.isNumeric {
            reuseIdentifier = Identifiers.SliderCell
        }

        let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath)
        if let cell = cell as? CharacteristicCell {
            cell.characteristic = characteristic
        }

        return cell
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return services[section].name
    }

    // MARK: HMAccessoryDelegate methods
    
    func accessory(accessory: HMAccessory, service: HMService, didUpdateValueForCharacteristic characteristic: HMCharacteristic) {
        if let index = service.characteristics.indexOf(characteristic) {
            let indexPath = NSIndexPath(forRow: index, inSection: 1)
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! CharacteristicCell
            cell.setValue(characteristic.value, notify: false)
        }
    }

    // MARK: Private hepler methods

    private func printServicesForAccessory(accessory: HMAccessory){
        print("Finding services for this accessory...")
        for service in accessory.services as [HMService]{
            print(" Service name is \(service.name)")
            print(" Service type is \(service.serviceType)")

            print(" Finding the characteristics for this service...")
            printCharacteristicsForService(service)
        }
    }

    private func printCharacteristicsForService(service: HMService){
        for characteristic in service.characteristics as [HMCharacteristic]{
            print("   Characteristic type is " + "\(characteristic.characteristicType)")
        }
    }
}
