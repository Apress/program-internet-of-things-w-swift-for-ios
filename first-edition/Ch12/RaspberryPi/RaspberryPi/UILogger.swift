//
//  UILogger.swift
//  RaspberryPi
//
//  Created by Gheorghe Chesler on 10/12/15.
//  Copyright © 2015 Devatelier. All rights reserved.
//

import Foundation
import UIKit

class UILogger {
    var textArea : UITextView!
    
    required init(out: UITextView) {
        dispatch_async(dispatch_get_main_queue()) {
            self.textArea = out
        };
        self.set()
    }
    
    func set(text: String?="") {
        dispatch_async(dispatch_get_main_queue()) {
            self.textArea!.text = text
        };
    }
    
    func logEvent(message: String) {
        dispatch_async(dispatch_get_main_queue()) {
            self.textArea!.text = self.textArea!.text.stringByAppendingString("=> " + message + "\n")
        };
    }
}