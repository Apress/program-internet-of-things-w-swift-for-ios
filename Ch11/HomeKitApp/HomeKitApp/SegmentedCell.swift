//
//  SegmentedCell.swift
//  HomeKitApp
//
//  Created by Manolo de la Torriente on 10/14/15.
//  Copyright © 2015 mdltorriente. All rights reserved.
//

import UIKit
import HomeKit

class SegmentetCell: CharacteristicCell {

    @IBOutlet weak var segmentedControl: UISegmentedControl!

    @IBAction func segmentValueChanged(sender: UISegmentedControl) {
        let value = titleValues[segmentedControl.selectedSegmentIndex]
        setValue(value, notify: true)
    }

    var titleValues = [Int]() {
        didSet {
            segmentedControl.removeAllSegments()
            for index in 0..<titleValues.count {
                let value: AnyObject = titleValues[index]
                let title = self.characteristic.descriptionForValue(value)
                segmentedControl.insertSegmentWithTitle(title, atIndex: index, animated: false)
            }
        }
    }

    override var characteristic: HMCharacteristic! {
        didSet {
            segmentedControl.userInteractionEnabled = reachable

            if let values = self.characteristic.allValues as? [Int] {
                titleValues = values
            }
        }
    }

    override func setValue(newValue: AnyObject?, notify: Bool) {
        super.setValue(newValue, notify: notify)
        if !notify {
            if let intValue = value as? Int, index = titleValues.indexOf(intValue) {
                segmentedControl.selectedSegmentIndex = index
            }
        }
    }
}
