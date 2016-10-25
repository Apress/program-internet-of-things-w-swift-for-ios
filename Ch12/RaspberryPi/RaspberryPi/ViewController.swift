//
//  ViewController.swift
//  RaspberryPi
//
//  Created by Gheorghe Chesler on 10/12/15.
//  Copyright © 2015 Devatelier. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet var clearButton : UIButton!
    @IBOutlet var labelButton : UIButton!
    @IBOutlet var labelButton2 : UIButton!
    @IBOutlet var textArea : UITextView!
    var api: APIClient!
    var logger: UILogger!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        api = APIClient(parent: self)
        logger = UILogger(out: textArea)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func unclickButton() {
        labelButton.setTitle("Blink All Lights", forState: UIControlState.Normal)
    }
    @IBAction func unclickButton2() {
        labelButton2.setTitle("Blink Red Light", forState: UIControlState.Normal)
    }
    @IBAction func clickButton() {
        logger.logEvent("=== Blink All Lights ===")
        api.blinkAllLights()
        labelButton.setTitle("Request Sent", forState: UIControlState.Normal)
    }
    @IBAction func clickButton2() {
        logger.logEvent("=== Blink Red Light ===")
        api.blinkLight("red")
        labelButton2.setTitle("Request Sent", forState: UIControlState.Normal)
    }
    @IBAction func clickClearButton() {
        logger.set()
    }
}

