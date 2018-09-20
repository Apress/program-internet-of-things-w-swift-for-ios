//
//  SecondViewController.swift
//  IOTHome
//
//  Created by Ahmed Bakir on 2018/02/20.
//  Copyright © 2018 Ahmed Bakir. All rights reserved.
//

import UIKit
import UserNotifications

class DoorViewController: UIViewController {

    @IBOutlet var statusLabel: UILabel?
    @IBOutlet var batteryLabel: UILabel?
    @IBOutlet var lastUpdatedLabel: UILabel?
    @IBOutlet var connectButton: UIButton?
    
    let dateFormatter = DateFormatter()
    
    var bluetoothService : BluetoothService?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        // Do any additional setup after loading the view, typically from a nib.
        bluetoothService = BluetoothService(delegate: self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let notificationCenter = UNUserNotificationCenter.current()
        
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { (completed: Bool, error: Error?) in
            NSLog("Notification request completed with status: \(completed)")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func connect() {
        bluetoothService?.connect()
    }

}

extension DoorViewController : BluetoothServiceDelegate {
    func didReceiveDoorUpdate(value: String) {
        let statusString = (value == "1") ? "Locked" : "Unlocked"
        let dateString = dateFormatter.string(from: Date())
        statusLabel?.text = statusString
        lastUpdatedLabel?.text = "(Last Updated: \(dateString))"
        let state = UIApplication.shared.applicationState
        
        if state == .background {
            scheduleLocalNotification(updateType: "Door", updateValue: value)
        }
    }
    
    func didReceiveBatteryUpdate(value: String) {
        batteryLabel?.text = "Battery Level: \(value)%"
        
        let state = UIApplication.shared.applicationState
        
        if state == .background {
            scheduleLocalNotification(updateType: "Battery level", updateValue: "\(value)%")
        }
    }
    
    func didUpdateConnection(status: ConnectionStatus) {
        switch status {
        case .connecting:
            connectButton?.setTitle("Connecting", for: .normal)
        case .connected:
            connectButton?.setTitle("Disconnect", for: .normal)
        case .scanning:
            connectButton?.setTitle("Scanning", for: .normal)
        default:
            connectButton?.setTitle("Connect", for: .normal)
        }
    }
    
    func scheduleLocalNotification(updateType: String, updateValue: String) {
        let notificationCenter = UNUserNotificationCenter.current()
        
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = "IOTHome device update"
        notificationContent.body = "\(updateType) is now \(updateValue)"
        notificationContent.sound = UNNotificationSound.default
        
        let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        
        let notificationRequest = UNNotificationRequest(identifier: "IOTHomeNotification", content: notificationContent, trigger: notificationTrigger)
        
        notificationCenter.add(notificationRequest) { (error: Error?) in
            if let errorObject = error {
                NSLog("Error scheduling notification: \(errorObject.localizedDescription)")
            } else {
                NSLog("Notification scheduled successfully")
            }
        }
    }
}

