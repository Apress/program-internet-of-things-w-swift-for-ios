//
//  UILogger.swift
//  FitBit Integration - Single Page
//
//  Created by Gheorghe Chesler on 4/13/15.
//  Copyright (c) 2015 DevAtelier. All rights reserved.
//
import Foundation
import UIKit

class UILogger {
    var textArea : UITextView!
    
    required init(out: UITextView) {
        textArea = out
        self.clear()
    }
    
    func clear() {
        textArea!.text = ""
    }
    
    func logEvent(message: String) {
        textArea!.text = textArea!.text.stringByAppendingString("=> " + message + "\n")
    }
}