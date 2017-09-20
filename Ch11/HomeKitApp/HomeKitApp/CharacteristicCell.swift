//
//  CharacteristicCell.swift
//  HomeKitApp
//
//  Copyright © 2015 mdltorriente. All rights reserved.
//

import UIKit
import HomeKit


class CharacteristicCell: UITableViewCell {

    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!

    var characteristic: HMCharacteristic! {
        didSet {
            var desc = characteristic.localizedDescription
            if characteristic.isReadOnly {
                desc = desc + " (Read Only)"
            } else if characteristic.isWriteOnly {
                desc = desc + " (Write Only)"
            }
            typeLabel.text = desc
            valueLabel?.text = "No Value"

            setValue(characteristic.value, notify: false)

            selectionStyle = characteristic.characteristicType == HMCharacteristicTypeIdentify ? .Default : .None

            if characteristic.isWriteOnly {
                return
            }

            if reachable {
                characteristic.readValueWithCompletionHandler { error in
                    if let error = error {
                        print("Error reading value for \(self.characteristic): \(error)")
                    } else {
                        self.setValue(self.characteristic.value, notify: false)
                    }
                }
            }
        }
    }

    var value: AnyObject?

    var reachable: Bool {
        return (characteristic.service?.accessory?.reachable ?? false)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func setValue(newValue: AnyObject?, notify: Bool) {
        self.value = newValue
        if let value = self.value {
            self.valueLabel?.text = self.characteristic.descriptionForValue(value)
        }

        if notify {
            self.characteristic.writeValue(self.value, completionHandler: { error in
                if let error = error {
                    print("Failed to write value for \(self.characteristic): \(error.localizedDescription)")
                }
            })
        }
    }
}
