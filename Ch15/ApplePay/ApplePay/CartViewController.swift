//
//  CartViewController.swift
//  ApplePay
//
//  Created by Gheorghe Chesler on 10/26/15.
//  Copyright © 2015 Devatelier. All rights reserved.
//

import Foundation
import PassKit
import Stripe

class CartViewController: UIViewController, PKPaymentAuthorizationViewControllerDelegate {
    
    var payButton: UIButton!
    let SupportedPaymentNetworks = [PKPaymentNetworkVisa, PKPaymentNetworkMasterCard, PKPaymentNetworkAmex]
    let ApplePayMerchantID = "merchant.com.DOMAIN.APPNAME"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        payButton = UIButton()
        payButton.setTitle("Pay", forState:.Normal)
        payButton.addTarget(self, action: "createToken", forControlEvents: .TouchUpInside)
        payButton.enabled = PKPaymentAuthorizationViewController.canMakePaymentsUsingNetworks(SupportedPaymentNetworks)
        view.addSubview(payButton)
    }
    
    func applePay(price: Double) {
        let item = PKPaymentSummaryItem(label: "CHARGE_NAME_HERE", amount: NSDecimalNumber(double: price))
        
        let request = PKPaymentRequest()
        request.merchantIdentifier = ApplePayMerchantID
        request.supportedNetworks = SupportedPaymentNetworks
        request.merchantCapabilities = .Capability3DS
        request.countryCode = "US"
        request.currencyCode = "USD"
        request.paymentSummaryItems = [item]
        if Stripe.canSubmitPaymentRequest(request) {
            let applePayController = PKPaymentAuthorizationViewController(paymentRequest: request)
            applePayController.delegate = self
            presentViewController(applePayController, animated: true, completion: nil)
        } else {
            //default to Stripe's PaymentKit Form
        }
    }
    
    func paymentAuthorizationViewController(controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, completion: ((PKPaymentAuthorizationStatus) -> Void)) {
        Stripe.createTokenWithPayment(payment) { token, error in
            if let token = token {
                //handle token to create charge in backend
                print("token: \(token)")
                completion(.Success)
            } else {
                completion(.Failure)
            }
        }
    }
    
    func paymentAuthorizationViewControllerDidFinish(controller: PKPaymentAuthorizationViewController) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
}