//
//  SliderCell.swift
//  HomeKitApp
//
//  Created by Manolo de la Torriente on 10/14/15.
//  Copyright © 2015 mdltorriente. All rights reserved.
//

import UIKit
import HomeKit

class SliderCell: CharacteristicCell {

    @IBOutlet weak var slider: UISlider!

    @IBAction func sliderValueChanged(sender: UISlider) {
        let value = roundedValueForSliderValue(slider.value)
        setValue(value, notify: true)
    }

    override var characteristic: HMCharacteristic! {
        didSet {
            slider.userInteractionEnabled = reachable
        }

        willSet {
            slider.minimumValue = newValue.metadata?.minimumValue as? Float ?? 0.0
            slider.maximumValue = newValue.metadata?.maximumValue as? Float ?? 100.0
        }
    }

    override func setValue(newValue: AnyObject?, notify: Bool) {
        super.setValue(newValue, notify: notify)
        if let newValue = newValue as? NSNumber where !notify {
            slider.value = newValue.floatValue
        }
    }

    private func roundedValueForSliderValue(value: Float) -> Float {
        if let metadata = characteristic.metadata,
            stepValue = metadata.stepValue as? Float where stepValue > 0 {
                let newValue = roundf(value / stepValue)
                let stepped = newValue * stepValue
                return stepped
        }
        return value
    }
}
