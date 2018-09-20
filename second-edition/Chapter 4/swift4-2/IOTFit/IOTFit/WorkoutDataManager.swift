//
//  WorkoutDataManager.swift
//  IOTFit
//
//  Created by Ahmed Bakir on 2018/01/24.
//  Copyright © 2018 Ahmed Bakir. All rights reserved.
//

import Foundation
import CoreLocation
import HealthKit

struct Coordinate : Codable {
    var latitude: Double
    var longitude: Double
}

struct Workout : Codable {
    var startTime: Date
    var endTime : Date
    var duration : TimeInterval
    var locations : [Coordinate]
    var workoutType : String
    var totalSteps : Double
    var flightsClimbed : Double
    var distance : Double
}

typealias Workouts = [Workout]

class WorkoutDataManager {
    
    static let sharedManager = WorkoutDataManager()
    
    private var workouts : Workouts?
    
    private var activeLocations : [CLLocationCoordinate2D]?
    
    private var healthStore : HKHealthStore?
    
    private init() {
        print("Singleton initialized")
        loadFromPlist()
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore.init()
        }
    }
    
    static func stringFromTime(timeInterval : TimeInterval) -> String {
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
    
    private var workoutsFileUrl : URL? {
        guard let documentsUrl = documentsDirectoryUrl() else {
            return nil
        }
        
        return documentsUrl.appendingPathComponent("Workouts.plist")
    }
    
    private var hkDataTypes : Set<HKSampleType> {
        var hkTypesSet = Set<HKSampleType>()
        if let stepCountType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount) {
            hkTypesSet.insert(stepCountType)
        }
        if let flightsClimbedType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.flightsClimbed) {
            hkTypesSet.insert(flightsClimbedType)
        }
        if let cyclingDistanceType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceCycling) {
            hkTypesSet.insert(cyclingDistanceType)
        }
        if let walkingDistanceType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning) {
            hkTypesSet.insert(walkingDistanceType)
        }
        
        hkTypesSet.insert(HKObjectType.workoutType())
        return hkTypesSet
    }
    
    func documentsDirectoryUrl() -> URL? {
        let fileManager = FileManager.default
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    func loadFromPlist() {

        workouts = [Workout]()
        
        guard let fileUrl = workoutsFileUrl else {
            return
        }
        
        do {
            let workoutData = try Data(contentsOf: fileUrl)
            let decoder = PropertyListDecoder()
            workouts = try decoder.decode(Workouts.self, from: workoutData)
        } catch {
            NSLog("Error reading plist")
        }
    }
    
    func saveToPlist() {
        guard let fileUrl = workoutsFileUrl else {
            return
        }

        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        do {
            let workoutData = try encoder.encode(workouts)
            try workoutData.write(to: fileUrl)
        } catch {
            NSLog("Error writing plist")
        }
        
    }
    
    func createNewWorkout() {
        activeLocations = [CLLocationCoordinate2D]()
    }
    
    func addLocation(coordinate: CLLocationCoordinate2D) {
        activeLocations?.append(coordinate)
    }
    
    func saveWorkout(_ workout : Workout) {
        
        var activeWorkout = workout
        
        guard let activeLocations = activeLocations else {
            return
        }
        
        let mappedCoordinates = activeLocations.map{(value : CLLocationCoordinate2D) in
            return Coordinate(latitude: value.latitude, longitude: value.longitude)
        }
        
        activeWorkout.locations = mappedCoordinates
        
        workouts?.append(activeWorkout)
        
        saveToPlist()
        
        saveWorkoutToHealthKit(activeWorkout)
    }
    
    func getLastWorkout() -> [CLLocationCoordinate2D]? {
        guard let workouts = workouts, let lastWorkout = workouts.last else {
            return nil
        }
        
        let locations = lastWorkout.locations.map{(value: Coordinate) in
            return CLLocationCoordinate2D(latitude: value.latitude, longitude: value.longitude)
        }
        return locations
    }
    
    
    //MARK: - HealthKit operations
    
    func loadWorkoutsFromHealthKit(completion: @escaping (([Workout]?) -> Void)) {
        healthStore?.requestAuthorization(toShare: hkDataTypes, read: hkDataTypes, completion: { [weak self] (isAuthorized : Bool, error : Error?) in
            //Request completed, it is now safe to use HealthKit
            if let error = error {
                NSLog("Error accessing HealthKit :\(error.localizedDescription)")
            } else {
                
                let workoutType = HKCategoryType.workoutType()
                let weekAgo = Date(timeIntervalSinceNow: -3600 * 24 * 7)
                let predicate = HKQuery.predicateForSamples(withStart: weekAgo, end: Date(), options: [])
                let sortDescriptor = NSSortDescriptor(key: "startDate", ascending: false)
                let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: 10, sortDescriptors: [sortDescriptor], resultsHandler: { (query: HKSampleQuery, samples : [HKSample]?, error : Error?) in
                    //
                    if let error = error {
                        NSLog("Error fetching items from HealthKit: \(error.localizedDescription)")
                        completion(nil)
                    } else {
                        guard let hkWorkouts = samples as? [HKWorkout] else {
                            completion(nil)
                            return
                        }
                        
                        let workouts = hkWorkouts.map({ (hkWorkout : HKWorkout) -> Workout in
                            let totalDistance = hkWorkout.totalDistance?.doubleValue(for: HKUnit.meter()) ?? 0
                            let flightsClimbed = hkWorkout.totalFlightsClimbed?.doubleValue(for: HKUnit.count()) ?? 0
                            var workoutType = WorkoutType.walking
                            
                            switch(hkWorkout.workoutActivityType) {
                                case .running:
                                    workoutType = WorkoutType.running
                                case .cycling:
                                    workoutType = WorkoutType.bicycling
                                default:
                                    workoutType = WorkoutType.walking
                            }
                            
                            return Workout(startTime: hkWorkout.startDate, endTime: hkWorkout.endDate, duration: hkWorkout.duration, locations: [], workoutType: workoutType, totalSteps: 0, flightsClimbed: flightsClimbed, distance: totalDistance)
                        })
                        completion(workouts)
                    }
                })
                self?.healthStore?.execute(query)
            }
        })
    }
    
    func saveWorkoutToHealthKit(_ workout : Workout) {
        healthStore?.requestAuthorization(toShare: hkDataTypes, read: hkDataTypes, completion: { [weak self] (isAuthorized : Bool, error : Error?) in
            
            if let error = error {
                NSLog("Error accessing HealthKit :\(error.localizedDescription)")
            } else {
                
                guard let workoutObject = self?.createHKWorkout(workout) else {
                    return
                }
                
                self?.healthStore?.save(workoutObject, withCompletion: { (completed: Bool, error: Error?) in
                    
                    if let error = error {
                        NSLog("Error creating workout object :\(error.localizedDescription)")
                    } else {
                        self?.addSamples(hkWorkout: workoutObject, workoutData: workout)
                    }
                })
                
            }
        })
    }
    
    func createHKWorkout(_ workout : Workout) -> HKWorkout? {
        
        let distanceQuantity = HKQuantity(unit: HKUnit.meter(), doubleValue: workout.distance)
        
        var activityType = HKWorkoutActivityType.walking
        
        switch(workout.workoutType) {
        case WorkoutType.running:
            activityType = HKWorkoutActivityType.running
        case WorkoutType.bicycling:
            activityType = HKWorkoutActivityType.cycling
        default:
            activityType = HKWorkoutActivityType.walking
        }
        return HKWorkout(activityType: activityType, start: workout.startTime, end: workout.endTime, duration: workout.duration, totalEnergyBurned: nil, totalDistance: distanceQuantity , device: nil, metadata: nil)
    }
    
    func addSamples(hkWorkout: HKWorkout, workoutData: Workout) {
        var samples = [HKSample]()
        addStepCountSample(workoutData, objectArray: &samples)
        addFlightsClimbedSample(workoutData, objectArray: &samples)
        addDistanceSample(workoutData, activityType: hkWorkout.workoutActivityType, objectArray: &samples)
        
        self.healthStore?.add(samples, to: hkWorkout, completion: { (saveCompleted: Bool, saveError: Error?) in
            if let saveError = saveError {
                NSLog("Error adding workout samples :\(saveError.localizedDescription)")
            } else {
                NSLog("Workout samples added successfully!")
            }
        })
    }
    
    func addStepCountSample(_ workoutData : Workout, objectArray: inout [HKSample]) {
        guard let stepQuantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount) else {
            return
        }
        let stepUnit = HKUnit.count()
        let stepQuantity = HKQuantity(unit: stepUnit, doubleValue: workoutData.totalSteps)
        let stepSample = HKQuantitySample(type: stepQuantityType, quantity: stepQuantity, start: workoutData.startTime, end: workoutData.endTime)
        objectArray.append(stepSample)
    }
    
    func addFlightsClimbedSample(_ workoutData : Workout, objectArray: inout [HKSample]) {
        guard let flightQuantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.flightsClimbed) else {
            return
        }
        let flightUnit = HKUnit.count()
        let flightQuantity = HKQuantity(unit: flightUnit, doubleValue: workoutData.flightsClimbed)
        let flightSample = HKQuantitySample(type: flightQuantityType, quantity: flightQuantity, start: workoutData.startTime, end: workoutData.endTime)
        objectArray.append(flightSample)
    }
    
    func addDistanceSample(_ workoutData: Workout, activityType: HKWorkoutActivityType, objectArray: inout [HKSample]) {
        guard let cyclingDistanceType = HKQuantityType.quantityType(forIdentifier:  HKQuantityTypeIdentifier.distanceCycling),
            let walkingDistanceType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning) else {
            return
        }
        let distanceUnit = HKUnit.meter()
        let distanceQuantity = HKQuantity(unit: distanceUnit, doubleValue: workoutData.distance)
        
        let distanceQuantityType = activityType == HKWorkoutActivityType.cycling ? cyclingDistanceType : walkingDistanceType

        let distanceSample = HKQuantitySample(type: distanceQuantityType, quantity: distanceQuantity, start: workoutData.startTime, end: workoutData.endTime)
        objectArray.append(distanceSample)
    }
}
