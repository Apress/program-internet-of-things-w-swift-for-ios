//
//  ViewController.swift
//  Using Keychain Services
//
//  Created by Gheorghe Chesler on 6/15/15.
//  Copyright © 2015 Devatelier. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet var clearButton : UIButton!
    @IBOutlet var clearKeychainButton : UIButton!
    @IBOutlet var saveButton : UIButton!
    @IBOutlet var readButton : UIButton!
    @IBOutlet var textArea : UITextView!
    @IBOutlet var textField : UITextField!
    var logger: UILogger!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        logger = UILogger(out: textArea)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func saveToKeychain() {
        var value = textField.text!;
        if value.isEmpty {
            let dateFormatter:NSDateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            value = dateFormatter.stringFromDate(NSDate())
        }
        logger.logEvent("Save to keychain: \(value)")
        Keychain.set("token", value: value)
    }
    @IBAction func readFromKeychain() {
        // the response is an Optional<NSData> so it needs to be unwrapped
        if let value = Keychain.get("token") {
            logger.logEvent("Read from keychain: \(value)")
        }
        else {
            logger.logEvent("No value found in the keychain")
        }
    }
    @IBAction func clickClearButton() {
        logger.clear()
    }
    @IBAction func clickClearKeychainButton() {
        Keychain.clear()
        logger.logEvent("The keychain data has been cleared")
    }
}

