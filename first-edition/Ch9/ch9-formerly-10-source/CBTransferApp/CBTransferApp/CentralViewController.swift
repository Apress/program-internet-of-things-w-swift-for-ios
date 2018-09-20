//
//  CentralViewController.swift
//  CBTransferApp
//
//  Copyright (c) 2015 mdltorriente. All rights reserved.
//

import UIKit

extension UIView {

    func rotate(fromValue: CGFloat, toValue: CGFloat, duration: CFTimeInterval = 1.0, completionDelegate: AnyObject? = nil) {

        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = fromValue
        rotateAnimation.toValue = toValue
        rotateAnimation.duration = duration
        
        if let delegate: AnyObject = completionDelegate {
            rotateAnimation.delegate = delegate
        }
        self.layer.addAnimation(rotateAnimation, forKey: nil)
    }
}


class CentralViewController: UIViewController, TransferServiceScannerDelegate {

    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    
    var scanner: TransferServiceScanner!
    var isScanning: Bool = false
    
    @IBAction func toggleScanning() {
        if isScanning {
            scanner.stopScan()
        } else {
            scanner.startScan()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        scanner = TransferServiceScanner(delegate: self)
    }

    override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        if isScanning == true {
            // if still scanning, restart the animation
            scanButton.rotate(0.0, toValue: CGFloat(M_PI * 2), completionDelegate: self)
        }
    }

    // MARK: TransferServiceScannerDelegate methods

    func didStartScan() {
        if !isScanning {
            textView.text = "Scanning..."
            isScanning = true
            scanButton.rotate(0.0, toValue: CGFloat(M_PI * 2), duration: 1.0, completionDelegate: self)
        }
    }

    func didStopScan() {
        textView.text = ""
        isScanning = false
    }

    func didTransferData(data: NSData?) {
        print("didTransferData")
        let stringFromData = NSString(data: data!, encoding: NSUTF8StringEncoding)
        textView.text = stringFromData as! String
    }
}
