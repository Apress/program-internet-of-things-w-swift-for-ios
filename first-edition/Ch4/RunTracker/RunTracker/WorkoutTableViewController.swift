//
//  ViewController.swift
//  RunTracker
//
//  Created by Ahmed Bakir on 10/18/15.
//  Copyright © 2015 Ahmed Bakir. All rights reserved.
//

import UIKit
import HealthKit

class WorkoutTableViewController: UITableViewController {

    var healthStore:  HKHealthStore?
    
    var workouts = [HKWorkout]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        // Do any additional setup after loading the view, typically from a nib.
        
        if (HKHealthStore.isHealthDataAvailable()) {
            
            healthStore = HKHealthStore()

            let stepType : HKQuantityType? = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)
            let distanceType : HKQuantityType? = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning)
            let workoutType : HKWorkoutType = HKObjectType.workoutType()
            
            let readTypes : Set =  [stepType!, distanceType!, workoutType]
            let writeTypes : Set = [stepType!, distanceType!,  workoutType]
            
            
            healthStore?.requestAuthorizationToShareTypes(writeTypes, readTypes: readTypes, completion: { (success: Bool, error: NSError?) -> Void in
                //set
                
                if success {
                    //success
                    
                    //get workouts
                    
                    let backgroundQuery = HKObserverQuery(sampleType: workoutType, predicate: nil, updateHandler: { (query: HKObserverQuery, handler: HKObserverQueryCompletionHandler, error: NSError? ) -> Void in
                        
                        if error == nil {
                                self.getWorkouts()
                        }
                        
                    })
                    
                    self.healthStore?.executeQuery(backgroundQuery)
                    
                    self.getWorkouts()
                    
                } else {
                    //Denied
                    self.presentErrorMessage("HealthKit permissions denied")
                    
                }
                
            })

            
        } else {
            //no health kit data available
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func getWorkouts() {
        
        let workoutType = HKObjectType.workoutType()
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        
        let now = NSDate()
        
        let calendar = NSCalendar.currentCalendar()
        
        let oneMonthAgo = calendar.dateByAddingUnit(NSCalendarUnit.Month, value: -1, toDate: now, options: NSCalendarOptions(rawValue: 0))
        
        let workoutPredicate = HKQuery.predicateForSamplesWithStartDate(oneMonthAgo, endDate: now, options: HKQueryOptions.None)
        
        let workoutQuery = HKSampleQuery(sampleType: workoutType, predicate: workoutPredicate, limit: 30, sortDescriptors: [sortDescriptor]) { (query: HKSampleQuery, results: [HKSample]?, error: NSError? ) -> Void in
            print("results are here")
            if error == nil {
                if let workouts = results as? [HKWorkout] {
                    self.workouts = workouts
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.tableView.reloadData()
                    })
                }
            } else {
                self.presentErrorMessage("Error fetching workouts")
            }
        }
        
        healthStore?.executeQuery(workoutQuery)

    }
    
    //mark - table view delegate
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return workouts.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("WorkoutCell", forIndexPath: indexPath)
        
        let workout = workouts[indexPath.row]
        
        let workoutTypeString : String
        let timeString = NSTimeInterval().toString(workout.duration)

        switch(workout.workoutActivityType) {
        case HKWorkoutActivityType.Running:
            workoutTypeString = "Running"
        case HKWorkoutActivityType.Walking:
            workoutTypeString = "Walking"
        case HKWorkoutActivityType.Elliptical:
            workoutTypeString = "Elliptical"
        default:
            workoutTypeString = "Other workout"
        }
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
        
        cell.textLabel?.text = "\(workoutTypeString) / \(timeString)"
        cell.detailTextLabel!.text = dateFormatter.stringFromDate(workout.startDate)
        
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "CreateWorkoutSegue") {
            
            if let navVC = segue.destinationViewController as? UINavigationController {
            
                if let createVC = navVC.viewControllers[0] as? CreateWorkoutViewController {
                    createVC.healthStore = self.healthStore
                }
                
            }
            
            
        }
    }
    
    func presentErrorMessage(errorString : String) {
        let alert = UIAlertController(title: "Error", message: errorString, preferredStyle: UIAlertControllerStyle.Alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
        alert.addAction(okAction)
        presentViewController(alert, animated: true, completion: nil)
    }

}

