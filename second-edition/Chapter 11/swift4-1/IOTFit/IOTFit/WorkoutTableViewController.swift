//
//  WorkoutTableViewController.swift
//  IOTFit
//
//  Created by Ahmed Bakir on 2018/02/08.
//  Copyright © 2018 Ahmed Bakir. All rights reserved.
//

import UIKit

class WorkoutTableViewController: UITableViewController {

    var workouts : [Workout]?
    let dateFormatter = DateFormatter()
    
    var securityView: SecurityView?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        dateFormatter.dateStyle = .medium
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        setupSecurityView()
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(showSecurityView), name: Notification.Name.UIApplicationWillResignActive, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        showSecurityView()
        
        WorkoutDataManager.sharedManager.loadWorkoutsFromHealthKit { [weak self] (fetchedWorkouts: [Workout]?) in
            if let fetchedWorkouts = fetchedWorkouts {
                self?.workouts = fetchedWorkouts
                DispatchQueue.main.async {
                    self?.tableView?.reloadData()
                }
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let securityView = securityView else { return 0 }
        if securityView.isHidden {
            return self.workouts?.count ?? 0
        } else {
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "workoutCell", for: indexPath)
        
        guard let workouts = workouts else {
            return cell
        }
        
        let selectedWorkout = workouts[indexPath.row]
        let dateString = dateFormatter.string(from: selectedWorkout.startTime)
        let durationString =  WorkoutDataManager.stringFromTime(timeInterval: selectedWorkout.duration)
        
        let titleText = "\(dateString) | \(selectedWorkout.workoutType) | \(durationString)"
        let detailText = String(format: "%.0f m | %.0f floors", arguments: [selectedWorkout.distance, selectedWorkout.flightsClimbed])
        
        // Configure the cell...
        cell.textLabel?.text = titleText
        cell.detailTextLabel?.text = detailText

        return cell
    }

    func setupSecurityView() {
        guard let securityNibItems = Bundle.main.loadNibNamed("SecurityView", owner: nil, options: nil),
            let securityView = securityNibItems.first as? SecurityView else { return }
        
        securityView.frame = view.frame
        securityView.autoresizingMask =  [.flexibleWidth, .flexibleHeight]
        securityView.delegate = self
        self.securityView = securityView
        
        view.addSubview(securityView)       
    }
    
    @objc func showSecurityView() {
        if let securityView = self.securityView, securityView.isHidden == true {
            tableView.reloadData()
            securityView.alpha = 1.0
            securityView.isHidden = false
            view.bringSubview(toFront: securityView)
        }
        
        securityView?.checkPasswordExistence()
    }
}

extension WorkoutTableViewController: SecurityViewDelegate {
    
    func needsInitialPassword() {
        let alert = UIAlertController(title: "Initial installation", message: "Please set a passcode for your data", preferredStyle: .alert)
        alert.addTextField { (textField: UITextField) in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
        }
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] (action: UIAlertAction) in
            guard let textField = alert.textFields?.first,
                let password = textField.text else { return }
            self?.securityView?.savePassword(password: password)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    
    func didSavePassword(success: Bool) {
        NSLog("Password save status: \(success)")
    }
    
    func didFinishWithError(description: String) {
        let alert = UIAlertController(title: "Authentication Error", message: description, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(alertAction)
        present(alert, animated: true)
    }
    
    func didFinishWithAuthenticationType(_ type: AuthenticationType) {
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            DispatchQueue.main.async {
                self?.securityView?.alpha = 0.0
                self?.securityView?.isHidden = true
                self?.securityView?.passwordTextField?.text = nil
                guard let securityView = self?.securityView else { return }
                self?.view.sendSubview(toBack: securityView)
                self?.tableView.reloadData()
            }
        })
    }
}
