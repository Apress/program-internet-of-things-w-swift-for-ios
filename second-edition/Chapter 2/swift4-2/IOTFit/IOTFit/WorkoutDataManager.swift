//
//  WorkoutDataManager.swift
//  IOTFit
//
//  Created by Ahmed Bakir on 2018/01/24.
//  Copyright © 2018 Ahmed Bakir. All rights reserved.
//

import Foundation
import CoreLocation

struct Coordinate : Codable {
    var latitude: Double
    var longitude: Double
}

struct Workout : Codable {
    var endTime : Date
    var duration : TimeInterval
    var locations : [Coordinate]
}

typealias Workouts = [Workout]

class WorkoutDataManager {
    
    static let sharedManager = WorkoutDataManager()
    
    private var workouts : Workouts?
    
    private var activeLocations : [CLLocationCoordinate2D]?
    
    private init() {
        print("Singleton initialized")
        loadFromPlist()
    }
    
    private var workoutsFileUrl : URL? {
        guard let documentsUrl = documentsDirectoryUrl() else {
            return nil
        }
        
        return documentsUrl.appendingPathComponent("Workouts.plist")
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
    
    func saveWorkout(duration : TimeInterval) {
        
        guard let activeLocations = activeLocations else {
            return
        }
        
        let mappedCoordinates = activeLocations.map{(value : CLLocationCoordinate2D) in
            return Coordinate(latitude: value.latitude, longitude: value.longitude)
        }
        
        let currentWorkout = Workout(endTime: Date(), duration: duration, locations: mappedCoordinates)
        
        workouts?.append(currentWorkout)
        
        saveToPlist()
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
}
