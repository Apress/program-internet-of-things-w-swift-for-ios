//
//  APIClient.swift
//  FitBit Integration - Single Page
//
//  Created by Gheorghe Chesler on 4/13/15.
//  Copyright (c) 2015 DevAtelier. All rights reserved.
//
import Foundation

class APIClient {
    var apiVersion: String!
    var baseURL: String = "http://127.0.0.1"
    var liveBaseURL: String = "https://api.fitbit.com"
    var liveAPIVersion: String = "1"
    var requestTokenURL: String = "https://api.fitbit.com/oauth/request_token"
    var accessTokenURL: String = "https://api.fitbit.com/oauth/access_token"
    var authorizeURL: String = "https://www.fitbit.com/oauth/authorize"
    var viewController: ViewController!
    var oauthParams: NSDictionary!
    var oauthHandler: OAuth1a!
    var rateLimit: Int!
    var rateLimitRemaining: Int!
    var rateLimitReset: Int!
    var rateLimitTimeStamp: Int!
    
    required init (parent: ViewController!) {
        viewController = parent
        oauthParams = [
            "oauth_consumer_key" : "6cf4162a72ac4a4382c098caec132782",
            "oauth_consumer_secret" : "c652d5fb28f344679f3b6b12121465af",
            "oauth_token" : "5a3ca2edf91d7175cad30bc3533e3c8a",
            "oauth_token_secret" : "da5bc974d697470a93ec59e9cfaee06d",
        ]
        oauthHandler = OAuth1a(oauthParams: oauthParams)
    }
    
    func goLive () {
        baseURL = liveBaseURL
        apiVersion = liveAPIVersion
    }
    
    func getBloodPressure (date: NSDate?=NSDate()) {
        // GET /1/user/-/bp/date/2010-02-21.json
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let currentDate = formatter.stringFromDate(date!)
        getData(APIService.USER, id: "-", urlSuffix: NSArray(array: ["bp/date", currentDate ]))
    }
    
    func setBloodPressure (date: NSDate?=NSDate()) {
        // POST /1/user/-/bp.json
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let currentDate = formatter.stringFromDate(date!)
        let request: [String:String] = ["diastolic":"80","systolic":"120","date": currentDate]
        postData(APIService.USER, id: "-", urlSuffix: NSArray(array: ["bp" ]), params: request)
    }
    
    func getBodyWeight (date: NSDate?=NSDate()) {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let currentDate = formatter.stringFromDate(date!)
        getData(APIService.USER, id: "-", urlSuffix: NSArray(array: ["body/log/weight/date", currentDate ]))
    }
    
    func setBodyWeight (date: NSDate?=NSDate()) {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let currentDate = formatter.stringFromDate(date!)
        let request: [String:String] = ["weight":"73","date": currentDate]
        postData(APIService.USER, id: "-", urlSuffix: NSArray(array: ["body/log/weight" ]), params: request)
    }
    
    func postData (service: APIService, id: String!=nil, urlSuffix: NSArray!=nil, params: [String:String]!=[:]) {
        let blockSelf = self
        let logger: UILogger = viewController.logger
        self.apiRequest(
            service,
            method: APIMethod.POST,
            id: id,
            urlSuffix: urlSuffix,
            inputData: params,
            callback: { (responseJson: NSDictionary!, responseError: NSError!) -> Void in
                if (responseError != nil) {
                    logger.logEvent(responseError!.description)
                    // Handle here the error response in some way
                }
                else {
                    blockSelf.processPOSTData(service, id: id, urlSuffix: urlSuffix, params: params, responseJson: responseJson)
                }
        })
    }
    
    func processPOSTData (service: APIService, id: String!, urlSuffix: NSArray!, params: [String:String]!=[:], responseJson: NSDictionary!) {
        // do something with data here
    }
    
    
    func getData (service: APIService, id: String!=nil, urlSuffix: NSArray!=nil, params: [String:String]!=[:]) {
        let blockSelf = self
        let logger: UILogger = viewController.logger
        self.apiRequest(
            service,
            method: APIMethod.GET,
            id: id,
            urlSuffix: urlSuffix,
            inputData: params,
            callback: { (responseJson: NSDictionary!, responseError: NSError!) -> Void in
                if (responseError != nil) {
                    logger.logEvent(responseError!.description)
                    // Handle here the error response in some way
                }
                else {
                    blockSelf.processGETData(service, id: id, urlSuffix: urlSuffix, params: params, responseJson: responseJson)
                }
            })
    }
    
    func processGETData (service: APIService, id: String!, urlSuffix: NSArray!, params: [String:String]!=[:], responseJson: NSDictionary!) {
        // do something with data here
    }
    
    func apiRequest (
        service: APIService,
        method: APIMethod,
        id: String!,
        urlSuffix: NSArray!,
        inputData: [String:String]!,
        callback: (responseJson: NSDictionary!, responseError: NSError!) -> Void ) {
        // Compose the base URL
        var serviceURL = baseURL + "/"
        if apiVersion != nil {
            serviceURL += apiVersion + "/"
        }
        serviceURL += service.toString()
        
        if id != nil && !id.isEmpty {
            serviceURL += "/" + id
        }
        let request = NSMutableURLRequest()
        request.HTTPMethod = method.toString()
        // The urlSuffix contains an array of strings that we use to compose the final URL
        if urlSuffix?.count > 0 {
            serviceURL += "/" + urlSuffix.componentsJoinedByString("/")
        }
        // All URLs need to have have at least the .json suffix, if not already defined
        if !serviceURL.hasSuffix(".json") && !serviceURL.hasSuffix(".xml") {
            serviceURL += ".json"
        }
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        request.URL = NSURL(string: serviceURL)
        // Sign the OAuth request here
        oauthHandler.signRequest(request, urlParameters: inputData)
        
        if !inputData.isEmpty {
            serviceURL += "?" + asURLString(inputData)
            request.URL = NSURL(string: serviceURL)
        }
        //now make the request
        let blockSelf = self
        let logger: UILogger = viewController.logger
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { (data : NSData?, urlResponse : NSURLResponse?, error: NSError?) -> Void in
            //the request returned with a response or possibly an error
            logger.logEvent("URL: " + serviceURL)
            var error: NSError?
            var jsonResult: NSDictionary?
            if urlResponse != nil {
                blockSelf.extractRateLimits(urlResponse!)
                let rData: String = NSString(data: data!, encoding: NSUTF8StringEncoding)! as String
                if data != nil {
                    
                    do {
                        try jsonResult = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary
                        
                        
                    } catch {
                        print("json error: \(error)")
                    }
                    
                    //jsonResult = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary
                }
                let logResponse: String! = blockSelf.prettyJSON(jsonResult)
                logResponse == nil
                    ? logger.logEvent("RESPONSE RAW: " + (rData.isEmpty ? "No Data" : rData) )
                    : logger.logEvent("RESPONSE JSON: \(logResponse)" )
                print("RESPONSE RAW: \(rData)\nRESPONSE SHA1: \(rData.sha1())")
            }
            else {
                error = NSError(domain: "response", code: -1, userInfo: ["reason":"blank response"])
            }
            callback(responseJson: jsonResult, responseError: error)
        }
        task.resume()
    }
    
    func asURLString (inputData: [String:String]!=[:]) -> String {
        var params: [String] = []
        for (key, value) in inputData {
            params.append( [ key.escapeUrl(), value.escapeUrl()].joinWithSeparator("=" ))
        }
        params = params.sort{ $0 < $1 }
        return params.joinWithSeparator("&")
    }
    
    
    func prettyJSON (json: NSDictionary!) -> String! {
        var pretty: String!
        if json != nil && NSJSONSerialization.isValidJSONObject(json!) {
            if let data = try? NSJSONSerialization.dataWithJSONObject(json!, options: NSJSONWritingOptions.PrettyPrinted) {
                pretty = NSString(data: data, encoding: NSUTF8StringEncoding) as? String
            }
        }
        return pretty
    }
    
    func extractRateLimits (response: NSURLResponse) {
        // Fitbit-Rate-Limit-Limit: 150
        // Fitbit-Rate-Limit-Remaining: 149
        // Fitbit-Rate-Limit-Reset: 1478
        if let urlResponse = response as? NSHTTPURLResponse {
            if let rl = urlResponse.allHeaderFields["Fitbit-Rate-Limit-Limit"] as? NSString as? String {
                rateLimit = Int(rl)
                print("RESPONSE HEADER rateLimit: \(rl)")
            }
            if let rlr = urlResponse.allHeaderFields["Fitbit-Rate-Limit-Remaining"] as? NSString as? String {
                rateLimitRemaining = Int(rlr)
                print("RESPONSE HEADER rateLimitRemaining: \(rlr)")
            }
            if let rlx = urlResponse.allHeaderFields["Fitbit-Rate-Limit-Reset"] as? NSString as? String {
                rateLimitReset = Int(rlx)
                rateLimitTimeStamp = Int(String(format:"%d", Int(NSDate().timeIntervalSince1970)))
                print("RESPONSE HEADER rateLimitReset: \(rlx), checked at: \(rateLimitTimeStamp)")
            }
        }
    }
}


enum APIService {
    case USER, ACTIVITIES, FOODS, GOOD_JSON, BAD_JSON
    func toString() -> String {
        var service: String!
        switch self {
        case .USER:
            service = "user"
        case .ACTIVITIES:
            service = "activities"
        case .FOODS:
            service = "foods"
        case .GOOD_JSON:
            service = "data"
        case .BAD_JSON:
            service = "badData"
        }
        return service
    }
}

enum APIMethod {
    case GET, PUT, POST, DELETE
    func toString() -> String {
        var method: String!
        switch self {
        case .GET:
            method = "GET"
        case .PUT:
            method = "PUT"
        case .POST:
            method = "POST"
        case .DELETE:
            method = "DELETE"
        }
        return method
    }
}

