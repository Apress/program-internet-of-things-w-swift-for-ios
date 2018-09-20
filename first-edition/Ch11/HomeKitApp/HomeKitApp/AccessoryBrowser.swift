//
//  AccessoryBrowser.swift
//  HomeKitApp
//
//  Copyright © 2015 mdltorriente. All rights reserved.
//

import UIKit
import HomeKit
import ExternalAccessory


class AccessoryBrowser: UITableViewController, HMAccessoryBrowserDelegate {

    let accessoryBrowser = HMAccessoryBrowser()
    var accessories = [HMAccessory]()
    var selectedAccessory: HMAccessory?

    override func viewDidLoad() {
        super.viewDidLoad()
        accessoryBrowser.delegate = self
        accessoryBrowser.startSearchingForNewAccessories()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    override func viewWillDisappear(animated: Bool) {
        accessoryBrowser.stopSearchingForNewAccessories()
    }

    @IBAction func done(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: UITableViewController methods

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accessories.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let accessory = accessories[indexPath.row];
        let cell = tableView.dequeueReusableCellWithIdentifier("AccessoryCell", forIndexPath: indexPath)
        cell.textLabel?.text = accessory.name
        cell.detailTextLabel?.text = accessory.category.localizedDescription
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        selectedAccessory = accessories[indexPath.row]
        HomeStore.sharedInstance.home?.addAccessory(self.selectedAccessory!, completionHandler: { error in

            if (error != nil) {
                print("Error: \(error)")
                UIAlertController.showErrorAlert(self, error: error!)

            } else {
                NSNotificationCenter.defaultCenter().postNotificationName(HomeStore.Notification.AddAccessoryNotification, object: nil)
                HomeStore.sharedInstance.home?.assignAccessory(self.selectedAccessory!, toRoom: (HomeStore.sharedInstance.home?.roomForEntireHome())!, completionHandler: { error in
                    if let error = error {
                        print("failed to assign accessory to room: \(error)")
                    } else {
                        print("added \(self.selectedAccessory!.name) to room")
                    }
                })
            }

        })
    }

    // MARK: HMAccessoryBrowserDelegate methods

    func accessoryBrowser(browser: HMAccessoryBrowser, didFindNewAccessory accessory: HMAccessory) {
        print("didFindNewAccessory \(accessory.name)")
        if !self.accessories.contains(accessory) {
            self.accessories.insert(accessory, atIndex: 0)
            let indexPath = NSIndexPath(forRow: 0, inSection: 0)
            tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
    }

    func accessoryBrowser(browser: HMAccessoryBrowser, didRemoveNewAccessory accessory: HMAccessory) {
        print("didRemoveNewAccessory \(accessory.name)")
        if let index = accessories.indexOf(accessory) {
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            accessories.removeAtIndex(index)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
    }
}
