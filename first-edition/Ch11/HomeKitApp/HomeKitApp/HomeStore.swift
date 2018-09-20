//
//  HomeStore
//  HomeKitApp
//
//  Copyright © 2015 mdltorriente. All rights reserved.
//

import HomeKit

class HomeStore: NSObject {

    static let sharedInstance = HomeStore()

    struct Notification {
        static let AddAccessoryNotification = "AddAccessoryNotification"
    }

    var homeManager: HMHomeManager = HMHomeManager()
    var home: HMHome?
}
