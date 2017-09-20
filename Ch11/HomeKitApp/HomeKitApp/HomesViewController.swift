//
//  HomesViewController.swift
//  HomeKitApp
//
//  Copyright (c) 2015 mdltorriente. All rights reserved.
//

import UIKit
import HomeKit


class HomesViewController: UITableViewController, HMHomeManagerDelegate {

    enum HomeSections: Int {
        case Homes = 0, PrimaryHome
        static let count = 2
    }

    struct Identifiers {
        static let addHomeCell = "AddHomeCell"
        static let noHomesCell = "NoHomesCell"
        static let primaryHomeCell = "PrimaryHomeCell"
        static let homeCell = "HomeCell"
    }

    var homeStore: HomeStore {
        return HomeStore.sharedInstance
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        homeStore.homeManager.delegate = self
    }

    // MARK: UITableView helpers

    func isHomesListEmpty() -> Bool {
        return homeStore.homeManager.homes.count == 0
    }

    func isIndexPathAddHome(indexPath: NSIndexPath) -> Bool {
        return indexPath.section == HomeSections.Homes.rawValue
            && indexPath.row == homeStore.homeManager.homes.count
    }

    // MARK: UITableView methods

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return HomeSections.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        let count = homeStore.homeManager.homes.count

        switch (section) {
        case HomeSections.PrimaryHome.rawValue:
            return max(count, 1)
        case HomeSections.Homes.rawValue:
            return count + 1
        default:
            break
        }

        return 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        if isIndexPathAddHome(indexPath) {
            return tableView.dequeueReusableCellWithIdentifier(Identifiers.addHomeCell, forIndexPath: indexPath)
        } else if isHomesListEmpty() {
            return tableView.dequeueReusableCellWithIdentifier(Identifiers.noHomesCell, forIndexPath: indexPath)
        }

        var reuseIdentifier: String?

        switch (indexPath.section) {
        case HomeSections.PrimaryHome.rawValue:
            reuseIdentifier = Identifiers.primaryHomeCell
        case HomeSections.Homes.rawValue:
            reuseIdentifier = Identifiers.homeCell
        default:
            break
        }

        let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier!, forIndexPath: indexPath) as UITableViewCell

        let home = homeStore.homeManager.homes[indexPath.row] as HMHome
        cell.textLabel?.text = home.name

        if indexPath.section == HomeSections.PrimaryHome.rawValue {
            if home == homeStore.homeManager.primaryHome {
                cell.accessoryType = .Checkmark
            } else {
                cell.accessoryType = .None
            }
        }

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        if isIndexPathAddHome(indexPath) {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            onAddHomeTouched()

        } else {
            homeStore.home = homeStore.homeManager.homes[indexPath.row]
            if HomeSections(rawValue: indexPath.section) == .PrimaryHome {
                let home = homeStore.homeManager.homes[indexPath.row]
                if home != homeStore.homeManager.primaryHome {
                    homeStore.homeManager.updatePrimaryHome(home, completionHandler: { error in
                        if let error = error {
                            UIAlertController.showErrorAlert(self, error: error)
                        } else {
                            let indexSet = NSIndexSet(index: HomeSections.PrimaryHome.rawValue)
                            tableView.reloadSections(indexSet, withRowAnimation: .Automatic)
                        }
                    })
                }
            }
        }
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return !isIndexPathAddHome(indexPath)
            && !isHomesListEmpty()
            && indexPath.section == HomeSections.Homes.rawValue
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {

        if (editingStyle == .Delete) {

            let home = homeStore.homeManager.homes[indexPath.row] as HMHome
            homeStore.homeManager.removeHome(home, completionHandler: { error in

                if error != nil {
                    print("Error \(error)")
                    return

                } else {
                    tableView.beginUpdates()
                    let primaryIndexPath = NSIndexPath(forRow: indexPath.row, inSection: HomeSections.PrimaryHome.rawValue)
                    if self.homeStore.homeManager.homes.count == 0 {
                        tableView.reloadRowsAtIndexPaths([primaryIndexPath], withRowAnimation: UITableViewRowAnimation.Fade)
                    } else {
                        tableView.deleteRowsAtIndexPaths([primaryIndexPath], withRowAnimation: .Automatic)
                    }
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                    tableView.endUpdates()
                }
            })
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == HomeSections.PrimaryHome.rawValue {
            return "Primary Home"
        }
        return nil
    }

    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == HomeSections.PrimaryHome.rawValue {
            return "Used by Siri to route commands when a home is not specified"
        }
        return nil
    }

    // MARK: HMHomeManagerDelegate methods

    func homeManagerDidUpdateHomes(manager: HMHomeManager) {
        print("homeManagerDidUpdateHomes")
        tableView.reloadData()
    }

    func homeManager(manager: HMHomeManager, didAddHome home: HMHome) {
        print("didAddHome \(home.name)")
    }

    func homeManager(manager: HMHomeManager, didRemoveHome home: HMHome) {
        print("didRemoveHome \(home.name)")
    }


    private func onAddHomeTouched() {

        let controller = UIAlertController(title: "Add Home", message: "Enter a name for the home", preferredStyle: .Alert)

        controller.addTextFieldWithConfigurationHandler({ textField in
            textField.placeholder = "My House"
        })

        controller.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))

        controller.addAction(UIAlertAction(title: "Add Home", style: .Default) { action in
            let textFields = controller.textFields as [UITextField]!
            if let homeName = textFields[0].text {

                if homeName.isEmpty {
                    let alert = UIAlertController(title: "Error", message: "Please enter a name", preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)

                } else {
                    self.homeStore.homeManager.addHomeWithName(homeName, completionHandler: { home, error in
                        if error != nil {
                            print("failed to add new home. \(error)")
                        } else {
                            print("added home \(home!.name)")
                            self.tableView.reloadData()
                        }
                    })
                }
            }
        })
        presentViewController(controller, animated: true, completion: nil)
    }
}


