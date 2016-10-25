//
//  PayViewController.swift
//  ApplePay
//
//  Created by Gheorghe Chesler on 10/26/15.
//  Copyright © 2015 Devatelier. All rights reserved.
//

import Foundation
import Stripe

class PayViewController: UIViewController, STPPaymentCardTextFieldDelegate {
    
    var payButton: UIButton!
    var paymentTextField: STPPaymentCardTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        paymentTextField = STPPaymentCardTextField()
        paymentTextField.center = view.center
        paymentTextField.delegate = self
        view.addSubview(paymentTextField)
        
        payButton = UIButton()
        payButton.setTitle("Pay", forState:.Normal)
        payButton.addTarget(self, action: "createToken", forControlEvents: .TouchUpInside)
        payButton.enabled = false
        view.addSubview(payButton)
    }
    
    func paymentCardTextFieldDidChange(textField: STPPaymentCardTextField) {
        payButton.enabled = textField.valid
    }
    
    func createToken() {
        let card = paymentTextField.card! as! STPCard
        Stripe.createTokenWithCard(card) { token, error in
            if let token = token {
                //send token to backend and create charge
                print("token: \(token)")
            }
        }
    }
}