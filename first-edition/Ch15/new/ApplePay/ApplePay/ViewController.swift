//
//  ViewController.swift
//  ApplePay
//
//  Created by Gheorghe Chesler on 10/26/15.
//  Copyright © 2015 Devatelier. All rights reserved.
//

import UIKit
import PassKit
import Stripe

class ViewController: UIViewController, STPPaymentCardTextFieldDelegate, PKPaymentAuthorizationViewControllerDelegate {
    let SupportedPaymentNetworks = [PKPaymentNetworkVisa, PKPaymentNetworkMasterCard, PKPaymentNetworkAmex]
    let ApplePayMerchantID = "merchant.com.iot.stripe"
    @IBOutlet var payButton: UIButton?
    @IBOutlet var textArea: UITextView!
    @IBOutlet var paymentTextField: STPPaymentCardTextField?
    @IBOutlet var paymentValueField: UITextField!
    var logger: UILogger!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        logger = UILogger(out: textArea)
        
        paymentTextField = STPPaymentCardTextField()
        paymentTextField?.center = view.center
        view.addSubview(paymentTextField!)
        paymentTextField?.delegate = self
        payButton?.enabled = PKPaymentAuthorizationViewController.canMakePaymentsUsingNetworks(SupportedPaymentNetworks)
    }
    func paymentCardTextFieldDidChange(textField: STPPaymentCardTextField) {
        payButton?.enabled = textField.valid
    }
    
    func paymentAuthorizationViewControllerDidFinish(controller: PKPaymentAuthorizationViewController) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func payWithApplePay(sender: UIButton) {
        logger.set()
        if let total = Double(paymentValueField.text!) {
            logger.logEvent("Pay with Apple Pay the amount: \(total)")
            self.applePay(total);
        }
        else {
            logger.logEvent("No valid amount specified")
        }
    }
    
    func applePay(price: Double) {
        let item = PKPaymentSummaryItem(label: "New Charge", amount: NSDecimalNumber(double: price))
        let request = PKPaymentRequest()
        request.merchantIdentifier = ApplePayMerchantID
        request.supportedNetworks = SupportedPaymentNetworks
        request.merchantCapabilities = .Capability3DS
        request.countryCode = "US"
        request.currencyCode = "USD"
        request.paymentSummaryItems = [item]
        if Stripe.canSubmitPaymentRequest(request) {
            logger.logEvent("Paying with Apple Pay and Stripe")
            // Apple Pay is available and the user created a valid credit card record
            let applePayController = PKPaymentAuthorizationViewController(paymentRequest: request)
            applePayController.delegate = self
            presentViewController(applePayController, animated: true, completion: nil)
        } else {
            logger.logEvent("Cannot submit Apple Pay payments")
            //default to Stripe's PaymentKit Form
        }
    }
    
    func paymentAuthorizationViewController(
        controller:                  PKPaymentAuthorizationViewController,
        didAuthorizePayment payment: PKPayment,
        completion:                  (PKPaymentAuthorizationStatus) -> Void) {
            let this = self
            Stripe.createTokenWithPayment(payment) { token, error in
                if let token = token {
                    this.logger.logEvent("Got a valid token: \(token)")
                    //handle token to create charge in backend
                    
                    
                    completion(.Success)
                } else {
                    this.logger.logEvent("Did not get a valid token")
                    completion(.Failure)
                }
            }
    }
}

