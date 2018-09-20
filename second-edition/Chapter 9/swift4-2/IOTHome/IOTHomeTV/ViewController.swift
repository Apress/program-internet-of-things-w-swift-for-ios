//
//  ViewController.swift
//  IOTHomeTV
//
//  Created by Ahmed Bakir on 2018/08/27.
//  Copyright © 2018 Ahmed Bakir. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController {
    
    @IBOutlet weak var forecastView: UIView?
    @IBOutlet weak var indoorView: UIView?
    @IBOutlet weak var outdoorView: UIView?
    @IBOutlet weak var lockView: UIView?
    
    @IBOutlet weak var firstDayLabel: UILabel?
    @IBOutlet weak var secondDayLabel: UILabel?
    @IBOutlet weak var thirdDayLabel: UILabel?
    
    @IBOutlet weak var tipLabel: UILabel?
    
    @IBOutlet weak var indoorTempLabel: UILabel?
    @IBOutlet weak var indoorHumidityLabel: UILabel?
    @IBOutlet weak var outdoorTempLabel: UILabel?
    @IBOutlet weak var outdoorHumidityLabel: UILabel?
    
    @IBOutlet weak var lockImageView: UIImageView?
    @IBOutlet weak var firstDayImageView: UIImageView?
    @IBOutlet weak var secondDayImageView: UIImageView?
    @IBOutlet weak var thirdDayImageView: UIImageView?
    
    let locationManager = CLLocationManager()
    var lastSavedLocation : CLLocation?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        applyEffects(to: [forecastView, indoorView, outdoorView, lockView], cornerRadius: 20)
        
        addFontAwesomeImage(to: lockImageView, name: .lock)
        addFontAwesomeImage(to: firstDayImageView, name: .sun)
        addFontAwesomeImage(to: secondDayImageView, name: .sun)
        addFontAwesomeImage(to: thirdDayImageView, name: .sun)
        
        locationManager.delegate = self
        
        fetchNetworkData()

        setupGestureHandlers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager.requestLocation()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    //MARK: - Gesture logic
    
    func setupGestureHandlers() {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.fetchNetworkData))
        tapRecognizer.allowedPressTypes = [NSNumber(value: UIPress.PressType.playPause.rawValue)]
        self.view.addGestureRecognizer(tapRecognizer)
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for pressEvent in presses {
            if pressEvent.type == .select {
                fetchNetworkData()
            }
        }
    }

    //MARK: - UI operations
    
    func addFontAwesomeImage(to imageView: UIImageView?, name: FontAwesome)  {
        guard let imageView = imageView else { return }
        imageView.image = UIImage.fontAwesomeIcon(name: name, style: .solid,
                                                  textColor: UIColor.black,
                                                  size: imageView.bounds.size)
    }
    
    func applyEffects(to views: [UIView?], cornerRadius: CGFloat) {
        for view in views {
            addBlurEffect(to: view)
            addRoundedCorners(to: view, cornerRadius: cornerRadius)
            addShadow(to: view, cornerRadius: cornerRadius)
        }
    }
    
    func addBlurEffect(to targetView: UIView?) {
        guard let targetView = targetView else { return }
        view.backgroundColor = UIColor.clear
        let blurEffect = UIBlurEffect(style: .regular)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = view.bounds
        targetView.addSubview(blurView)
        targetView.sendSubviewToBack(blurView)
    }
    
    func addRoundedCorners(to targetView: UIView?, cornerRadius: CGFloat) {
        guard let targetView = targetView else { return }
        targetView.layer.cornerRadius = cornerRadius
        targetView.layer.masksToBounds = true
    }
    
    func addShadow(to targetView: UIView?, cornerRadius: CGFloat) {
        guard let targetView = targetView else { return }
        let shadowView = UIView(frame: targetView.frame)
        shadowView.layer.cornerRadius = cornerRadius

        shadowView.layer.shadowOffset = CGSize.zero
        shadowView.layer.shadowOpacity = 0.2
        shadowView.layer.shadowRadius = 10.0
        shadowView.layer.shadowColor = UIColor.black.cgColor
        
        let shadowPath = UIBezierPath(roundedRect: shadowView.bounds, cornerRadius: cornerRadius)
        shadowView.layer.shadowPath = shadowPath.cgPath
        
        view.addSubview(shadowView)
        view.bringSubviewToFront(targetView)
    }
    
    //MARK: - Network calls
    @IBAction func fetchNetworkData() {
        NetworkManager.shared.getTemperature { [weak self] (resultDict: [String: Any]) in
            
            if let error = resultDict["error"] as? String {
                self?.tipLabel?.text = "Error: \(error)"
            } else {
                DispatchQueue.main.async {
                    if let temperature = resultDict["temperature"] as? String {
                        self?.indoorTempLabel?.text = "\(temperature) C"
                    }
                    
                    if let humidity = resultDict["humidity"] as? String {
                        self?.indoorHumidityLabel?.text = "Humidity \(humidity)%"
                    }
                }
            }
        }
        
        NetworkManager.shared.getDoorStatus{ [weak self] (resultDict: [String: Any]) in
            
            if let error = resultDict["error"] as? String {
                self?.tipLabel?.text = "Error: \(error)"
            } else {
                DispatchQueue.main.async { [weak self] in
                    if let doorStatus = resultDict["doorStatus"] as? String {
                        if doorStatus == "0" {
                            self?.addFontAwesomeImage(to: self?.lockImageView, name: .lockOpen)
                        } else {
                            self?.addFontAwesomeImage(to: self?.lockImageView, name: .lock)
                        }
                    }
                }
            }
        }
        
        fetchOutdoorTemperature()
    }
    
    func fetchOutdoorTemperature() {
        guard let latitude = lastSavedLocation?.coordinate.latitude,
            let longitude = lastSavedLocation?.coordinate.longitude else {
                return
        }
        
        NetworkManager.shared.getOutdoorTemperature(latitude: "\(latitude)", longitude: "\(longitude)") { [weak self] (resultDict: [String: Any]) in
            
            if let error = resultDict["error"] as? String {
                self?.tipLabel?.text = "Error: \(error)"
            } else {
                guard let mainDict = resultDict["main"] as? [String: Any] else {
                    self?.tipLabel?.text = "Error: Invalid response"
                    return
                }
                
                if let humidity = mainDict["humidity"] {
                    self?.outdoorHumidityLabel?.text = "Humidity \(humidity)%"
                }
                
                if let temperature = mainDict["temp"] {
                    self?.outdoorTempLabel?.text = "\(temperature) C"
                }
            }
        }
        
        NetworkManager.shared.getForecast(latitude: "\(latitude)", longitude: "\(longitude)") { [weak self] (resultDict: [String: Any]) in
            
            if let error = resultDict["error"] as? String {
                self?.tipLabel?.text = "Error: \(error)"
            } else {
                guard let resultList = resultDict["list"] as? [Any] else {
                    self?.tipLabel?.text = "Error: Invalid response"
                    return
                }
                
                guard resultList.count > 15 else { return }
                //today
                self?.setupForecastView(dictionary: resultList[0], index: 0)
                //tommorrow
                self?.setupForecastView(dictionary: resultList[7], index: 1)
                //the day after
                self?.setupForecastView(dictionary: resultList[15], index: 2)
            }
        }
    }
    
    func setupForecastView(dictionary: Any, index: Int) {
        guard let dayDict = dictionary as? [String: Any]
        else { return }
        guard let mainDict = dayDict["main"] as? [String: Any]
        else { return }
        guard let weatherArray = dayDict["weather"] as? [Any] else { return }
        guard let weatherDict = weatherArray.first as? [String: Any] else { return }
        guard let minTemp = mainDict["temp_min"] as? Double else { return }
        guard let maxTemp = mainDict["temp_max"] as? Double else { return }
        guard let conditionCode = weatherDict["id"] as? Int else { return }
        
        let icon: FontAwesome
        switch conditionCode {
            case 300...599: icon = .umbrella
            case 600...699: icon = .snowflake
            case 700...799: icon = .exclamationTriangle
            case 800: icon = .sun
            default: icon = .cloud
        }
        
        switch index {
        case 0:
            guard let imageView = firstDayImageView else { return }
            firstDayLabel?.text = "\(maxTemp) / \(minTemp)"
            firstDayImageView?.image = UIImage.fontAwesomeIcon(name: icon, style: .solid,
                                                               textColor: UIColor.black,
                                                               size: imageView.bounds.size)
        case 1:
            guard let imageView = secondDayImageView else { return }
            secondDayLabel?.text = "\(maxTemp) / \(minTemp)"
            secondDayImageView?.image = UIImage.fontAwesomeIcon(name: icon, style: .solid,
                                                               textColor: UIColor.black,
                                                               size: imageView.bounds.size)
        default:
            guard let imageView = thirdDayImageView else { return }
            thirdDayLabel?.text = "\(maxTemp) / \(minTemp)"
            thirdDayImageView?.image = UIImage.fontAwesomeIcon(name: icon, style: .solid,
                                                               textColor: UIColor.black,
                                                               size: imageView.bounds.size)
        }
    }
}

extension ViewController : CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        NSLog("Authorization state: \(status)")
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastSavedLocation = locations.first
        
        fetchOutdoorTemperature()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let errorString = "Location error: \(error.localizedDescription)"
        tipLabel?.text = errorString
        NSLog(errorString)
    }
}

