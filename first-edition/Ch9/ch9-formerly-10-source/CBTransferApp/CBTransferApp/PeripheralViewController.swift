//
//  PeripheralViewController.swift
//  CBTransferApp
//
//  Copyright (c) 2015 mdltorriente. All rights reserved.
//

import UIKit
import CoreBluetooth

class PeripheralViewController: UIViewController, UITextViewDelegate, TransferServiceDelegate {
    
    @IBOutlet weak var advertiseSwitch: UISwitch!
    @IBOutlet weak var textView: UITextView!
    
    var transferService: TransferService!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        advertiseSwitch.setOn(false, animated: true)
        transferService = TransferService(delegate: self)
        textView.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textViewDidChange(textView: UITextView) {
        print("textViewDidChange")
        if advertiseSwitch.on {
            advertiseSwitch.setOn(false, animated: true)
            transferService.stopAdvertising()
        }
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        print("textViewDidBeginEditing")
        let rightButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Done, target: self, action: "dismissKeyboard")
        navigationItem.rightBarButtonItem = rightButton
    }
    
    @IBAction func advertiseSwitchDidChange() {
        if advertiseSwitch.on {
            transferService.startAdvertising()
        } else {
            transferService.stopAdvertising()
        }
    }
    
    func dismissKeyboard() {
        textView.resignFirstResponder()
        navigationItem.rightBarButtonItem = nil
    }
   
    // MARK: TransferServiceDelegate methods
    
    func didPowerOn() {
        
    }
    
    func didPowerOff() {
        advertiseSwitch.setOn(false, animated: true)
    }
    
    func getDataToSend() -> NSData {
        return textView.text.dataUsingEncoding(NSUTF8StringEncoding)!
    }
}

