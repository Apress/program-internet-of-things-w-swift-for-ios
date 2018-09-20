//
//  ViewController.swift
//  ApplePay
//
//  Created by Gheorghe Chesler on 10/26/15.
//  Copyright © 2015 Devatelier. All rights reserved.
//

import UIKit
import PassKit

class ViewController: UIViewController {

    var payButton: UIButton!
    let SupportedPaymentNetworks = [PKPaymentNetworkVisa, PKPaymentNetworkMasterCard, PKPaymentNetworkAmex]
    let ApplePayMerchantID = "merchant.com.example.stripe"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

