//
//  RecordInterfaceController.swift
//  IOTFitWatch Extension
//
//  Created by Ahmed Bakir on 2018/09/02.
//  Copyright © 2018 Ahmed Bakir. All rights reserved.
//

import WatchKit
import Foundation
import CoreLocation
import CoreMotion

class RecordInterfaceController: WKInterfaceController {

    @IBOutlet var timeLabel: WKInterfaceLabel?
    @IBOutlet var workoutLabel: WKInterfaceLabel?
    @IBOutlet var progressLabel: WKInterfaceLabel?
    
    @IBOutlet var toggleButton: WKInterfaceButton?
    @IBOutlet var exitButton: WKInterfaceButton?
    
    var currentWorkoutState = WorkoutState.inactive
    var currentWorkoutType = WorkoutType.unknown
    
    var workoutStartTime : Date?
    var lastSavedTime : Date?
    var workoutDuration : TimeInterval = 0.0
    var workoutTimer : Timer?
    
    var workoutAltitude : Double = 0.0
    var workoutDistance : Double = 0.0
    var averagePace : Double = 0.0
    var floorsAscended : Double = 0.0
    var workoutSteps : Double = 0.0
    
    var lastSavedLocation : CLLocation?
    
    var isMotionAvailable : Bool = false
    
    let locationManager = CLLocationManager()
    var pedometer : CMPedometer?
    var motionManager : CMMotionActivityManager?
    var altimeter : CMAltimeter?
    
    //UI intiialization
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        updateUserInterface()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    @IBAction func exit() {
        dismiss()
    }
    
    //app state management
    
    func updateUserInterface() {
        
        switch(currentWorkoutState) {
        case .active:
            toggleButton?.setTitle("Pause")
        case .paused:
            toggleButton?.setTitle("Resume")
        default:
            toggleButton?.setTitle("Start")
        }
    }
    
    func resetWorkoutData() {
        lastSavedTime = Date()
        workoutDuration = 0.0
        workoutDistance = 0.0
        workoutAltitude = 0.0
        workoutSteps = 0
        floorsAscended = 0
        averagePace = 0.0
        currentWorkoutType = WorkoutType.unknown
    }
    
    func startWorkout() {
        currentWorkoutState = .active
        UserDefaults.standard.setValue(true, forKey: "isConfigured")
        UserDefaults.standard.synchronize()
        workoutTimer = Timer.scheduledTimer(timeInterval: timerInterval, target: self, selector: #selector(updateWorkoutData), userInfo: nil, repeats: true)
        locationManager.startUpdatingLocation()
        lastSavedTime = Date()
        workoutStartTime = Date()
        WorkoutDataManager.sharedManager.createNewWorkout()
        
        if (CMMotionManager().isDeviceMotionAvailable && CMPedometer.isStepCountingAvailable() && CMAltimeter.isRelativeAltitudeAvailable()) {
            isMotionAvailable = true
            
            startPedometerUpdates()
            startActivityUpdates()
            startAltimeterUpdates()
            
        } else {
            NSLog("Motion acitivity not available on device.")
            isMotionAvailable = false
        }
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
            pedometer?.stopUpdates()
            motionManager?.stopActivityUpdates()
            altimeter?.stopRelativeAltitudeUpdates()
            
            if let workoutStartTime = workoutStartTime {
                let workout = Workout(startTime: workoutStartTime, endTime: Date(), duration: workoutDuration, locations: [], workoutType: self.currentWorkoutType, totalSteps: workoutSteps, flightsClimbed: floorsAscended, distance: workoutDistance)
                WorkoutDataManager.sharedManager.saveWorkout(workout)
            }
        default:
            NSLog("toggleWorkout() called out of context!")
        }
        updateUserInterface()
    }
    
    @objc func updateWorkoutData() {
        let now = Date()
        
        if let lastTime = lastSavedTime {
            self.workoutDuration += now.timeIntervalSince(lastTime)
        }
        
        if currentWorkoutType != WorkoutType.unknown {
            workoutLabel?.setText("\(currentWorkoutType)")
        }
        
        let timeString = WorkoutDataManager.stringFromTime(timeInterval: self.workoutDuration)
        let progressString = String(format: "%.2fm | %.0f steps", arguments: [workoutDistance, workoutSteps])
        timeLabel?.setText(timeString)
        progressLabel?.setText(progressString)
        lastSavedTime = now
    }
    
    func startPedometerUpdates() {
        
        guard let workoutStartTime = workoutStartTime else {
            return
        }
        
        pedometer = CMPedometer()
        pedometer?.startUpdates(from: workoutStartTime, withHandler: { [weak self] (pedometerData : CMPedometerData?, error: Error?) in
            NSLog("Received pedometer update!")
            if let error = error {
                NSLog("Error reading pedometer data: \(error.localizedDescription)")
                return
            }
            
            guard let pedometerData = pedometerData,
                let distance = pedometerData.distance as? Double,
                let averagePace = pedometerData.averageActivePace as? Double,
                let steps = pedometerData.numberOfSteps as? Int,
                let floorsAscended = pedometerData.floorsAscended as? Int else {
                    return
            }
            self?.workoutDistance = distance
            self?.floorsAscended = Double(floorsAscended)
            self?.workoutSteps = Double(steps)
            self?.averagePace = averagePace
        })
    }
    
    func startActivityUpdates() {
        
        motionManager = CMMotionActivityManager()
        motionManager?.startActivityUpdates(to: OperationQueue.main, withHandler: { [weak self] (activity : CMMotionActivity?) in
            guard let activity = activity else {
                return
            }
            if activity.walking {
                self?.currentWorkoutType = WorkoutType.walking
            } else if activity.running {
                self?.currentWorkoutType = WorkoutType.running
            } else if activity.cycling {
                self?.currentWorkoutType = WorkoutType.bicycling
            } else if activity.stationary {
                self?.currentWorkoutType = WorkoutType.stationary
            } else {
                self?.currentWorkoutType = WorkoutType.unknown
            }
        })
    }
    
    func startAltimeterUpdates() {
        altimeter = CMAltimeter()
        altimeter?.startRelativeAltitudeUpdates(to: OperationQueue.main, withHandler: { [weak self] (altitudeData : CMAltitudeData?, error: Error?) in
            if let error = error {
                NSLog("Error reading altimeter data: \(error.localizedDescription)")
                return
            }
            
            guard let altitudeData = altitudeData,
                let relativeAltitude = altitudeData.relativeAltitude as? Double else {
                    return
            }
            self?.workoutAltitude = relativeAltitude
        })
    }
    
    func requestLocationPermission() {
        
        if CLLocationManager.locationServicesEnabled() {
            
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.distanceFilter = 10.0  // In meters.
            //locationManager.pausesLocationUpdatesAutomatically = true
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.delegate = self
            
            switch(CLLocationManager.authorizationStatus()) {
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse :
                requestAlwaysPermission()
            case .authorizedAlways:
                resetWorkoutData()
                startWorkout()
            default:
                NSLog("Unable to request location")
            }
            
        } else {
            NSLog("Unable to init location")
        }
    }
    
    func requestAlwaysPermission() {
        if let isConfigured = UserDefaults.standard.value(forKey: "isConfigured") as? Bool, isConfigured == true {
            startWorkout()
        } else {
            locationManager.requestAlwaysAuthorization()
        }
    }
}

extension RecordInterfaceController : CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse:
            requestAlwaysPermission()
        case .authorizedAlways:
            resetWorkoutData()
            startWorkout()
        case .denied:
            NSLog("location permission denied")
        default:
            NSLog("Unhandled Location Manager Status: \(status)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let mostRecentLocation = locations.last else {
            NSLog("Unable to read most recent location")
            return
        }
        lastSavedLocation = mostRecentLocation
        NSLog("Most recent location: \(String(describing: mostRecentLocation))")
        
        WorkoutDataManager.sharedManager.addLocation(coordinate: mostRecentLocation.coordinate)
    }
}
