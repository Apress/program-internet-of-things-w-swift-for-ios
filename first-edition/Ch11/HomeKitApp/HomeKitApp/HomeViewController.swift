//
//  HomeViewController.swift
//  HomeKitApp
//
//  Copyright © 2015 mdltorriente. All rights reserved.
//

import UIKit
import HomeKit

class HomeViewController: UITableViewController, HMHomeDelegate {

    var homeStore: HomeStore {
        return HomeStore.sharedInstance
    }
    var home: HMHome! {
        return homeStore.home
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        home?.delegate = self
        title = homeStore.home!.name

        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "updateAccessories",
            name: HomeStore.Notification.AddAccessoryNotification, object: nil)
    }

    func updateAccessories() {
        print("updateAccessories selector called from NSNotificationCenter")
        tableView.reloadData()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ServicesSegue" {
            let controller = segue.destinationViewController as! ServicesViewController
            let indexPath = tableView.indexPathForSelectedRow;
            controller.accessory = homeStore.home!.accessories[(indexPath?.row)!];
        }
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {

        if homeStore.home?.accessories.count == 0 {
            setBackgroundMessage("No Accessories")
        } else {
            setBackgroundMessage(nil)
        }
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return homeStore.home!.accessories.count
        }
        return 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let accessory = homeStore.home!.accessories[indexPath.row];
        let reuseIdentifier = "AccessoryCell"

        let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath)
        cell.textLabel?.text = accessory.name

        let accessoryName = accessory.name
        let roomName = accessory.room!.name
        let inIdentifier = NSLocalizedString("%@ in %@", comment: "Accessory in Room")
        cell.detailTextLabel?.text = String(format: inIdentifier, accessoryName, roomName)
        return cell
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return homeStore.home?.accessories.count != 0 ? "Accessories" : ""
        }
        return nil
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.section == 1 {
            return true
        }
        return false
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {

        if (editingStyle == .Delete) {

            let accessory = homeStore.home?.accessories[indexPath.row]
            homeStore.home?.removeAccessory(accessory!, completionHandler: { error in
                if error != nil {
                    print("Error \(error)")
                    UIAlertController.showErrorAlert(self, error: error!)

                } else {
                    tableView.beginUpdates()
                        let rowAnimation = self.homeStore.home?.accessories.count == 0 ? UITableViewRowAnimation.Fade : UITableViewRowAnimation.Automatic
                        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: rowAnimation)
                    tableView.endUpdates()
                    tableView.reloadData()
                }
            })
        }
    }

    // MARK: HMHomeDelegate methods

    func home(home: HMHome, didAddAccessory accessory: HMAccessory) {
        print("didAddAccessory \(accessory.name)")
        tableView.reloadData()
    }

    func home(home: HMHome, didRemoveAccessory accessory: HMAccessory) {
        print("didRemoveAccessory \(accessory.name)")
        tableView.reloadData()
    }

    // MARK: Private methods

    private func setBackgroundMessage(message: String?) {
        if let message = message {
            let label = UILabel()
            label.text = message
            label.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
            label.textColor = UIColor.lightGrayColor()
            label.textAlignment = .Center
            label.sizeToFit()
            tableView.backgroundView = label
            tableView.separatorStyle = .None
        }
        else {
            tableView.backgroundView = nil
            tableView.separatorStyle = .SingleLine
        }
    }
}
