//
//  FirstViewController.swift
//  IOTHome
//
//  Created by Ahmed Bakir on 2018/02/20.
//  Copyright © 2018 Ahmed Bakir. All rights reserved.
//

import UIKit

class HomeViewController: DoorViewController {
    
    @IBOutlet var temperatureLabel: UILabel?
    @IBOutlet var humidityLabel: UILabel?
    
    var sensorData: [String: Any]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NetworkManager.shared.disconnectDoor { (resultDict: [String: Any]) in
            NSLog("Disconnect result: \(resultDict.description)")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction override func connect() {
        //Put network init code here
        NetworkManager.shared.getTemperature { [weak self] (resultDict: [String: Any]) in
            
            if let error = resultDict["error"] as? String {
                self?.displayError(errorString: error)
            } else {
                DispatchQueue.main.async {
                    if let temperature = resultDict["temperature"] as? String {
                        self?.temperatureLabel?.text = "\(temperature) C"
                    }
                    
                    if let humidity = resultDict["humidity"] as? String {
                        self?.humidityLabel?.text = "\(humidity)%"
                    }
                }
            }
        }
        
        NetworkManager.shared.getDoorStatus{ [weak self] (resultDict: [String: Any]) in
            
            if let error = resultDict["error"] as? String {
                self?.displayError(errorString: error)
            } else {
                DispatchQueue.main.async {
                    if let doorStatus = resultDict["doorStatus"] as? String {
                        self?.statusLabel?.text = "\(doorStatus)"
                    }
                    
                    if let batteryStatus = resultDict["batteryStatus"] as? String {
                        self?.batteryLabel?.text = "\(batteryStatus)"
                    }
                    
                    if let lastUpdate = resultDict["lastUpdate"] as? String {
                        self?.lastUpdatedLabel?.text = "\(lastUpdate)"
                    }
                }
            }
        }
    }
    
    func displayError(errorString: String) {
        let alertView = UIAlertController(title: "Error", message: errorString, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertView.addAction(alertAction)
        
        DispatchQueue.main.async { [weak self] in
            self?.present(alertView, animated: true, completion: nil)
        }
    }
}
