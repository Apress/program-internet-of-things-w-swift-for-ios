//
//  UIAlertControllerExtension.swift
//  HomeKitApp
//
//  Copyright © 2015 mdltorriente. All rights reserved.
//

import UIKit

extension UIAlertController {

    class func showErrorAlert(host: UIViewController, error: NSError) {
        let controller = UIAlertController(title: "Error", message: error.description, preferredStyle: .Alert)
        controller.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: nil))
        host.presentViewController(controller, animated: true, completion: nil)
    }
}

