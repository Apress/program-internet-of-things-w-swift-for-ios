//
//  InterfaceController.swift
//  IOTFitWatch Extension
//
//  Created by Ahmed Bakir on 2018/02/12.
//  Copyright © 2018 Ahmed Bakir. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {

    @IBOutlet var workoutTable: WKInterfaceTable?
    var workouts : [Workout]?
    let dateFormatter = DateFormatter()
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        dateFormatter.dateStyle = .medium
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        WorkoutDataManager.sharedManager.loadWorkoutsFromHealthKit { [weak self] (fetchedWorkouts: [Workout]?) in
            if let fetchedWorkouts = fetchedWorkouts {
                self?.workouts = fetchedWorkouts
                DispatchQueue.main.async {
                    self?.refreshTable()
                }
            }
        }
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    @IBAction func presentRecordInterface() {
        presentController(withName: "RecordInterfaceController", context: nil)
    }
    
    func refreshTable() {
        guard let workouts = workouts else { return }
        workoutTable?.setNumberOfRows(workouts.count, withRowType: "WorkoutRow")
        
        for index in 0..<workouts.count {
            guard let row = workoutTable?.rowController(at: index) as? WorkoutRowController else { return }
            
            let selectedWorkout = workouts[index]
            let dateString = dateFormatter.string(from: selectedWorkout.startTime)
            let durationString =  WorkoutDataManager.stringFromTime(timeInterval: selectedWorkout.duration)

            let detailText = String(format: "%.0f m | %@", arguments: [selectedWorkout.distance, durationString])
            
            row.dateLabel?.setText(dateString)
            row.durationLabel?.setText(detailText)
            
            let icon: FontAwesome
            
            switch selectedWorkout.workoutType {
            case WorkoutType.walking:
                icon = FontAwesome.walking
            case WorkoutType.bicycling:
                icon = FontAwesome.bicycle
            case WorkoutType.automotive:
                icon = FontAwesome.car
            default:
                icon = FontAwesome.dumbbell
            }
            
            let faImage = UIImage.fontAwesomeIcon(name: icon, style: .solid, textColor: UIColor.white, size: CGSize(width: 50, height: 50))
            row.icon?.setImage(faImage)
        }
    }
}
