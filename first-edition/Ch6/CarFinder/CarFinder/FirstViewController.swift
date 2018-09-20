//
//  FirstViewController.swift
//  CarFinder
//
//  Created by Ahmed Bakir on 10/28/15.
//  Copyright © 2015 Ahmed Bakir. All rights reserved.
//

import UIKit
import CoreLocation
import WatchConnectivity

class FirstViewController: UITableViewController, WCSessionDelegate {

    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        
        if (WCSession.isSupported()) {
            let session = WCSession.defaultSession()
            session.delegate = self
            session.activateSession()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        

        switch (CLLocationManager.authorizationStatus()) {
            
        case .AuthorizedWhenInUse, .AuthorizedAlways:
            locationManager.startUpdatingLocation()
        case .Denied:
            let alert = UIAlertController(title: "Permissions error", message: "This app needs location permission to work accurately", preferredStyle: UIAlertControllerStyle.Alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
            alert.addAction(okAction)
            presentViewController(alert, animated: true, completion: nil)
            
        case .NotDetermined:
            fallthrough
        default:
            locationManager.requestWhenInUseAuthorization()
        }
        
        self.tableView.reloadData()
    }
    
    //override func didUpdateLocations()

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return entries.count
        return DataManager.sharedInstance.locations.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("LocationCell", forIndexPath: indexPath)
        cell.tag = indexPath.row
        // Configure the cell...

        let entry : CLLocation = DataManager.sharedInstance.locations[indexPath.row]
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "hh:mm:ss, MM-dd-yyyy"

        cell.textLabel?.text = "\(entry.coordinate.latitude), \(entry.coordinate.longitude) "
            
        cell.detailTextLabel?.text = dateFormatter.stringFromDate(entry.timestamp)

        return cell
    }

    
    @IBAction func addLocation(sender: UIBarButtonItem) {
        
        
        var location = CLLocation(latitude: 32.830579, longitude: -117.153839)
        
        //var location : CLLocation = manager.location!
        
        if (CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse) {
            if let currentLocation = locationManager.location as CLLocation! {
                location = currentLocation
            }
        }
        
        DataManager.sharedInstance.locations.insert(location, atIndex: 0)
        
        tableView.reloadData()

        if (WCSession.isSupported()) {
            do {
                let locationArray = createLocationArray(DataManager.sharedInstance.locations)
                let userDict = ["Locations": locationArray]
                try WCSession.defaultSession().updateApplicationContext(userDict)
            } catch {
                //print ("Error \(error.code)")
                
                print("Error transferring data")
            }
        }
        
    }
    
    func createLocationArray(inputArray: [CLLocation]) -> [Dictionary<String, AnyObject>] {
        //for lo
        var outputArray = [Dictionary<String, AnyObject>]()
        
        for var index = 0; index < inputArray.count; index++ {
            let location = inputArray[index]
            let locationDict = ["Latitude" : location.coordinate.latitude , "Longitude" : location.coordinate.longitude, "Timestamp" : location.timestamp]
            outputArray.append(locationDict)
        }
        return outputArray
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
