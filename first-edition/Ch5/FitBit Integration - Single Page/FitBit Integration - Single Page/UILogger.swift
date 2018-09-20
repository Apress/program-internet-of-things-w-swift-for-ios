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
        dispatch_async(dispatch_get_main_queue()) {
            self.textArea = out
        };
        self.clear()
    }
    
    func clear() {
        dispatch_async(dispatch_get_main_queue()) {
            self.textArea!.text = ""
        };
    }
    
    func logEvent(message: String) {
        dispatch_async(dispatch_get_main_queue()) {
            self.textArea!.text = self.textArea!.text.stringByAppendingString("> " + message + "\n")
        };
    }
}