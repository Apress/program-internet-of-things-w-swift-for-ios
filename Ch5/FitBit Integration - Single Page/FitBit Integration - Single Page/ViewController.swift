//
//  ViewController.swift
//  FitBit Integration - Single Page
//
//  Created by Gheorghe Chesler on 3/30/15.
//  Copyright (c) 2015 DevAtelier. All rights reserved.
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
        api.goLive()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func unclickButton() {
        labelButton.setTitle("Good Request", forState: UIControlState.Normal)
    }
    @IBAction func unclickButton2() {
        labelButton2.setTitle("Bad Request", forState: UIControlState.Normal)
    }
    @IBAction func clickButton() {
        logger.logEvent("=== Good Request ===")
        // api.getData(APIService.GOOD_JSON) // TEST CALL
        //api.getData(APIService.USER, id: "-", urlSuffix: NSArray(array: ["profile"]))
        //api.setBloodPressure()
        //api.getBloodPressure()
        api.setBodyWeight()
        api.getBodyWeight()
        labelButton.setTitle("Good Request Sent", forState: UIControlState.Normal)
    }
    
    @IBAction func clickButton2() {
        logger.logEvent("=== Bad Request ===")
        api.getData(APIService.BAD_JSON)
        labelButton2.setTitle("Bad Request Sent", forState: UIControlState.Normal)
    }
    @IBAction func clickClearButton() {
        logger.clear()
    }
}

