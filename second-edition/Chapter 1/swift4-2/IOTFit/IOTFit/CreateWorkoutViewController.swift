//
//  FirstViewController.swift
//  IOTFit
//
//  Created by Ahmed Bakir on 2018/01/20.
//  Copyright © 2018 Ahmed Bakir. All rights reserved.
//

import UIKit

class CreateWorkoutViewController: UIViewController {

    @IBOutlet weak var workoutTimeLabel : UILabel?
    @IBOutlet weak var workoutDistanceLabel : UILabel?
    
    @IBOutlet weak var toggleWorkoutButton : UIButton?
    @IBOutlet weak var pauseWorkoutButton : UIButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func toggleWorkout() {
        NSLog("Toggle workout button pressed")
    }
    
    @IBAction func pauseWorkout() {
        NSLog("Pause workout button pressed")
    }

}

