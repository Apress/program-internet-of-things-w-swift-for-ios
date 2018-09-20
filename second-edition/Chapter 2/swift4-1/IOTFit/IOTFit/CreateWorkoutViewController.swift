//
//  FirstViewController.swift
//  IOTFit
//
//  Created by Ahmed Bakir on 2018/01/07.
//  Copyright © 2018 Ahmed Bakir. All rights reserved.
//

import UIKit
import CoreLocation

enum WorkoutState {
    case inactive
    case active
    case paused
}

let timerInterval : TimeInterval = 1.0

class CreateWorkoutViewController: UIViewController {

    let locationManager = CLLocationManager()
    
    @IBOutlet weak var workoutTimeLabel : UILabel?
    @IBOutlet weak var workoutDistanceLabel : UILabel?
    
    @IBOutlet weak var toggleWorkoutButton : UIButton?
    @IBOutlet weak var pauseWorkoutButton : UIButton?
    
    var currentWorkoutState = WorkoutState.inactive
    
    var lastSavedTime : Date?
    var workoutDuration : TimeInterval = 0.0
    var workoutTimer : Timer?
    
    var workoutDistance : Double = 0.0
    var lastSavedLocation : CLLocation?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        updateUserInterface()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func startWorkout() {
        currentWorkoutState = .active
        UserDefaults.standard.setValue(true, forKey: "isConfigured")
        UserDefaults.standard.synchronize()
        workoutTimer = Timer.scheduledTimer(timeInterval: timerInterval, target: self, selector: #selector(updateWorkoutData), userInfo: nil, repeats: true)
        locationManager.startUpdatingLocation()
        lastSavedTime = Date()
        WorkoutDataManager.sharedManager.createNewWorkout()
    }
    
    func stopWorkoutTimer() {
        workoutTimer?.invalidate()
    }
    
    @IBAction func toggleWorkout() {
        
        switch currentWorkoutState {
        case .inactive:
            requestLocationPermission()
        case .active:
            currentWorkoutState = .inactive
            stopWorkoutTimer()
            WorkoutDataManager.sharedManager.saveWorkout(duration: workoutDuration)
        default:
            NSLog("toggleWorkout() called out of context!")
        }
        
        updateUserInterface()
    }
    
    @IBAction func pauseWorkout() {
        
        switch currentWorkoutState {
        case .paused:
            startWorkout()
        case .active:
            currentWorkoutState = .paused
            lastSavedTime = nil
            stopWorkoutTimer()
            //pause updates
        default:
            NSLog("pauseWorkout() called out of context!")
        }
        
        updateUserInterface()
    }
    
    func updateUserInterface() {
        
        switch(currentWorkoutState) {
        case .active:
            toggleWorkoutButton?.setTitle("Stop", for: .normal)
            pauseWorkoutButton?.setTitle("Pause", for: .normal)
            pauseWorkoutButton?.isHidden = false
        case .paused:
             pauseWorkoutButton?.setTitle("Resume", for: .normal)
             pauseWorkoutButton?.isHidden = false
        default:
            toggleWorkoutButton?.setTitle("Start", for: .normal)
            pauseWorkoutButton?.setTitle("Pause", for: .normal)
            pauseWorkoutButton?.isHidden = true
            
        }
    }
    
    func stringFromTime(timeInterval : TimeInterval) -> String {
        let integerDuration = Int(timeInterval)
        let seconds = integerDuration % 60
        let minutes = (integerDuration / 60) % 60
        let hours = (integerDuration / 3600)
        
        if hours > 0 {
            return String("\(hours) hrs \(minutes) mins \(seconds) secs")
        } else {
            return String("\(minutes) min \(seconds) secs")
        }
    }
    
    @objc func updateWorkoutData() {
        let now = Date()
        if let lastTime = lastSavedTime {
            self.workoutDuration += now.timeIntervalSince(lastTime)
        }
        
        workoutTimeLabel?.text = stringFromTime(timeInterval: self.workoutDuration)
        
        workoutDistanceLabel?.text = String(format: "%.2f meters", arguments: [workoutDistance])
        
        lastSavedTime = now
    }
    
    func requestLocationPermission() {
        
        if CLLocationManager.locationServicesEnabled() {
            
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.distanceFilter = 10.0  // In meters.
            locationManager.pausesLocationUpdatesAutomatically = true
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.delegate = self
            
            switch(CLLocationManager.authorizationStatus()) {
                case .notDetermined:
                    locationManager.requestWhenInUseAuthorization()
                case .authorizedWhenInUse :
                    requestAlwaysPermission()
                case .authorizedAlways:
                    lastSavedTime = Date()
                    workoutDuration = 0.0
                    workoutDistance = 0.0
                    startWorkout()
                default:
                    presentPermissionErrorAlert()
            }
            
        } else {
            presentEnableLocationAlert()
        }
    }
    
    func requestAlwaysPermission() {
        if let isConfigured = UserDefaults.standard.value(forKey: "isConfigured") as? Bool, isConfigured == true {
            startWorkout()
        } else {
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    func presentEnableLocationAlert() {
        let alert = UIAlertController(title: "Permission Error", message: "Please enable location services on your device", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func presentPermissionErrorAlert() {
        let alert = UIAlertController(title: "Permission Error", message: "Please enable location services for this app", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: { (action : UIAlertAction) in
            if let settingsUrl = URL(string: UIApplicationOpenSettingsURLString), UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: nil)
            }
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }

}

extension CreateWorkoutViewController : CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse:
            requestAlwaysPermission()
        case .authorizedAlways:
            lastSavedTime = Date()
            workoutDuration = 0.0
            workoutDistance = 0.0
            startWorkout()
        case .denied:
            presentPermissionErrorAlert()
        default:
            NSLog("Unhandled Location Manager Status: \(status)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let mostRecentLocation = locations.last else {
            NSLog("Unable to read most recent location")
            return
        }
        
        if let savedLocation = lastSavedLocation {
            let distanceDelta = savedLocation.distance(from: mostRecentLocation)
            workoutDistance += distanceDelta
        }
        
        lastSavedLocation = mostRecentLocation
        NSLog("Most recent location: \(String(describing: mostRecentLocation))")
        
        WorkoutDataManager.sharedManager.addLocation(coordinate: mostRecentLocation.coordinate)
    }
    
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        NSLog("Location tracking paused")
    }
    
    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        NSLog("Location tracking resumed")
    }
}
