//
//  CreateWorkoutViewController.swift
//  RunTracker
//
//  Created by Ahmed Bakir on 10/25/15.
//  Copyright © 2015 Ahmed Bakir. All rights reserved.
//

import UIKit
import HealthKit
import CoreMotion

class CreateWorkoutViewController: UIViewController {

    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var toggleButton: UIButton!
    
    var workoutActive = false
    var healthStore:  HKHealthStore?
    var startDate : NSDate?
    var initialStartDate : NSDate?
    
    var timer: NSTimer?
    
    var lastActivity : CMMotionActivity?
    
    var pedometer : CMPedometer?
    var duration : NSTimeInterval = 0
    var sampleArray = [HKSample]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func toggleWorkout(sender: UIButton) {
        
        if (workoutActive) {
            
            self.stopWorkout()
            
        } else {
            
            self.startWorkout()
            
        }
        workoutActive = !workoutActive
        
    }
    
    func startWorkout() {
        self.timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "updateTime", userInfo: nil, repeats: true)
        
        if initialStartDate == nil {
            initialStartDate = NSDate()
        }
        startDate = NSDate()
        
        //start counting steps
        toggleButton.backgroundColor = UIColor.redColor()
        toggleButton.setTitle("Pause workout", forState: UIControlState.Normal)
        
        if (CMMotionActivityManager.isActivityAvailable() && CMPedometer.isStepCountingAvailable()) {
            pedometer = CMPedometer()
            
            //show total steps
            
            pedometer?.startPedometerUpdatesFromDate(initialStartDate!, withHandler: { (data: CMPedometerData?, error: NSError?) -> Void in
                //
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    let numberOfSteps = data?.numberOfSteps.integerValue
                    self.progressLabel.text = "\(numberOfSteps!) steps"
                })
                
            })
            
            let activityManager = CMMotionActivityManager()
            
            activityManager.startActivityUpdatesToQueue(NSOperationQueue.mainQueue(), withHandler: { (activity: CMMotionActivity?) -> Void in
                
                
                if activity?.stationary == false {
                    self.lastActivity = activity
                }
                
                var activityString = "Other activity type"
                
                if (activity?.stationary == true) {
                    activityString = "Stationary"
                }
                
                if (activity?.walking == true) {
                    activityString = "Walking"
                }
                
                if (activity?.running == true) {
                    activityString = "Running"
                }
                
                if (activity?.cycling == true) {
                    activityString = "Cycling"
                }
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.typeLabel.text = activityString
                })
                
                
            })
            
            
        } else {
            presentErrorMessage("Pedometer not available")
        }

    }
    
    func stopWorkout() {
        //stop the workout
        
        self.timer?.invalidate()
        
        //pause timer
        toggleButton.backgroundColor = UIColor.blueColor()
        toggleButton.setTitle("Continue workout", forState: UIControlState.Normal)
        
        //save steps
        if (pedometer != nil && startDate != nil) {
            let now = NSDate()
            
            pedometer?.stopPedometerUpdates()
            
            pedometer?.queryPedometerDataFromDate(startDate!, toDate: now, withHandler: { (data: CMPedometerData?, error: NSError?) -> Void in
                if (error == nil) {
                    
                    if let activityType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount) {
                        
                        let numberOfSteps = data?.numberOfSteps.doubleValue
                        
                        let countUnit = HKUnit(fromString: "count")
                        
                        let stepQuantity = HKQuantity(unit: countUnit, doubleValue: numberOfSteps!)
                        
                        let activitySample = HKQuantitySample(type: activityType, quantity: stepQuantity, startDate: self.startDate!, endDate: now)
                        
                        self.healthStore?.saveObject(activitySample, withCompletion: { (completed : Bool, error : NSError?) -> Void in
                            if (error == nil) {
                                
                                //add to sample array
                                self.sampleArray.append(activitySample)
                                
                            } else {
                                self.presentErrorMessage("Error saving steps")
                            }
                        })
                        
                    }
                    
                } else {
                    self.presentErrorMessage("Could not access pedometer")
                }
            })
            
            //increase duration
            duration += now.timeIntervalSinceDate(startDate!)
        }
    }
    
    
    @IBAction func close(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func done(sender: UIBarButtonItem) {
        
        //create new workout object
        let now = NSDate()
        
        if workoutActive {
            self.stopWorkout()
        }
        
        
        var workoutType = HKWorkoutActivityType.Walking
        
        if lastActivity != nil {
            if (lastActivity?.walking == true) {
                workoutType = HKWorkoutActivityType.Walking
            }
            if (lastActivity?.running == true) {
                workoutType = HKWorkoutActivityType.Running
            }
            
            if (lastActivity?.cycling == true) {
                workoutType = HKWorkoutActivityType.Cycling
            }
        }
        
        if initialStartDate != nil {
            
            let workout = HKWorkout(activityType: workoutType, startDate: initialStartDate!, endDate: now)
            
            self.healthStore?.saveObject(workout, withCompletion: { (completed: Bool, error: NSError?) -> Void in
                //workout
                
                if error == nil {
                    
                    self.healthStore?.addSamples(self.sampleArray, toWorkout: workout, completion: { (completed : Bool, error: NSError?) -> Void in
                        //
                        if error == nil {
                            print("steps saved successfully!")
                            
                            self.dismissViewControllerAnimated(true, completion: nil)
                            
                        } else {
                            self.presentErrorMessage("Error adding steps")
                        }
                    })
                    
                } else {
                    self.presentErrorMessage("Error saving workout")
                }
            })

            //add samples
            
            //save

        }
        
    }
    
    func presentErrorMessage(errorString : String) {
        let alert = UIAlertController(title: "Error", message: errorString, preferredStyle: UIAlertControllerStyle.Alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
        alert.addAction(okAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func updateTime() {
        
        let now = NSDate()
        
        if (startDate != nil) {
            let totalTime : NSTimeInterval = duration + now.timeIntervalSinceDate(startDate!)
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.timeLabel!.text = NSTimeInterval().toString(totalTime)
            })
        }
    }
    
}
