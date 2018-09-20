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
                    //self?.tableView?.reloadData()
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
}
