//
//  ViewController.swift
//  FitBit
//
//  Created by Gheorghe Chesler on 11/22/15.
//  Copyright © 2015 Devatelier. All rights reserved.
//

import UIKit
import AeroGearHttp
import AeroGearOAuth2

public class FitBitConfig: Config {
    public  init(clientId: String, scopes: [String], accountId: String? = nil, isOpenIDConnect: Bool = false) {
//        let bundleString = NSBundle.mainBundle().bundleIdentifier ?? "fitbit"
        super.init(base: "https://api.fitbit.com",
            authzEndpoint: "https://www.fitbit.com/oauth2/authorize",
//            redirectURL: "\(bundleString):/oauth2Callback",
            redirectURL: "https://localhost/oauth2Callback",
            accessTokenEndpoint: "oauth2/token",
            clientId: clientId,
            refreshTokenEndpoint: "oauth2/token",
            scopes: scopes,
            accountId: accountId)
    }
}

extension AccountManager {
    public class func addFitBitAccount(config: FitBitConfig ) -> OAuth2Module {
        return AccountManager.addAccount(config, moduleClass: OAuth2Module.self)
    }

}

class ViewController: UIViewController {
    @IBOutlet var clearButton : UIButton!
    @IBOutlet var loginButton : UIButton!
    @IBOutlet var textArea : UITextView!
    var logger: UILogger!
    var http: Http!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        logger = UILogger(out: textArea)
        self.http = Http()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func clickLoginButton() {
        logger.logEvent("=== LOGIN ===")
        let fitbitConfig = FitBitConfig(
            clientId: "229P3D",
            scopes:["profile","weight"], accountId: "")
        
        let gdModule = AccountManager.addFitBitAccount(fitbitConfig)
        self.http.authzModule = gdModule // Inject the AuthzModule into the HTTP layer object
        
        
        self.http.GET("https://api.fitbit.com/1/user/-/profile.json", completionHandler: {(response, error) in
            if (error != nil) {
                self.logger.logEvent("Error: " + error!.localizedDescription)
            } else {
                self.logger.logEvent("Success: " + response!.string)
            }
        })
    }

    @IBAction func clickClearButton() {
        logger.set()
    }}

