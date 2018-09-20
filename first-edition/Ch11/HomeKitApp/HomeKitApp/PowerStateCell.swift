//
//  PowerStateCell.swift
//  HomeKitApp
//
//  Created by Manolo de la Torriente on 10/13/15.
//  Copyright © 2015 mdltorriente. All rights reserved.
//

import UIKit
import HomeKit

class PowerStateCell: CharacteristicCell {

    @IBOutlet weak var powerSwitch: UISwitch!

    @IBAction func switchValueChanged(sender: UISwitch) {
        setValue(powerSwitch.on, notify: true)
    }

    override var characteristic: HMCharacteristic! {
        didSet {
            powerSwitch.userInteractionEnabled = reachable
        }
    }

    override func setValue(newValue: AnyObject?, notify: Bool) {
        super.setValue(newValue, notify: notify)
        if let newValue = newValue as? Bool where !notify {
            powerSwitch.setOn(newValue, animated: true)
        }
    }
}
