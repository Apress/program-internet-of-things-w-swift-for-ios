//
//  NetworkManager.swift
//  IOTHome
//
//  Created by Ahmed Bakir on 2018/08/26.
//  Copyright © 2018 Ahmed Bakir. All rights reserved.
//

import Foundation

class NetworkManager: NSObject, URLSessionDelegate {
    
    let deviceBaseUrl = "https://raspberrypi.local"
    let opmBaseUrl = "https://api.openweathermap.org/data/2.5"
    let opmApiKey = "PUT YOUR KEY HERE"
    static let shared = NetworkManager()

    func formattedUrl(baseUrl: String, endpoint: String, parameters: [String: String]? ) -> URL? {
        guard var urlComponents = URLComponents(string: "\(baseUrl)/\(endpoint)") else {
            return nil
        }
        
        urlComponents.queryItems = parameters?.compactMap({ pair in
            URLQueryItem(name: pair.key, value: pair.value)
        })
        
        return urlComponents.url?.absoluteURL
    }
    
    func request(baseUrl: String, endpoint: String, httpMethod: String, parameters: [String: String]? = nil, completion: @escaping (_ jsonDict: [String: Any]) -> Void) {

        guard let url = self.formattedUrl(baseUrl: baseUrl, endpoint: endpoint, parameters: parameters) else {
            return completion(["error": "Invalid URL"])
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = httpMethod
        
        let session: URLSession = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
        
        let task = session.dataTask(with: urlRequest) { (data: Data?, url: URLResponse?, error: Error?) in
            if error == nil {
                do  {
                    guard let jsonData = data else {
                        return completion(["error": "Invalid input data"])
                    }
                    guard let result = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String : Any] else { return completion(["error": "Invalid JSON data"]) }
                    completion(result)
                    
                } catch let error {
                    return completion(["error": error.localizedDescription])
                }
            } else {
                guard let errorObject = error else { return completion(["error": "Invalid error object"]) }
                return completion(["error": errorObject.localizedDescription])
            }
        }
        
        task.resume()
    }
    
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        let method = challenge.protectionSpace.authenticationMethod
        let host = challenge.protectionSpace.host
        NSLog("Received challenge for \(host)")
        switch (method, host) {
        case (NSURLAuthenticationMethodServerTrust, "theta3dev.local"):
            let trust = challenge.protectionSpace.serverTrust!
            let credential = URLCredential(trust: trust)
            completionHandler(.useCredential, credential)
        default:
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    //network requests
    
    func getOutdoorTemperature(latitude: String, longitude: String, completion: @escaping (_ jsonDict: [String: Any]) -> Void) {
        
        let parameters = ["appid": opmApiKey,
                          "lat": latitude,
                          "lon": longitude,
                          "units": "metric"]
        request(baseUrl: opmBaseUrl, endpoint: "weather", httpMethod: "GET", parameters: parameters) { (resultDict: [String: Any]) in
            completion(resultDict)
        }
    }
    
    func getForecast(latitude: String, longitude: String, completion: @escaping (_ jsonDict: [String: Any]) -> Void) {
        
        let parameters = ["appid": opmApiKey,
                          "lat": latitude,
                          "lon": longitude,
                          "units": "metric"]
        request(baseUrl: opmBaseUrl, endpoint: "forecast", httpMethod: "GET", parameters: parameters) { (resultDict: [String: Any]) in
            completion(resultDict)
        }
    }
    
    func getTemperature(completion: @escaping (_ jsonDict: [String: Any]) -> Void) {
        request(baseUrl: deviceBaseUrl, endpoint: "temperature", httpMethod: "GET") { (resultDict: [String: Any]) in
            completion(resultDict)
        }
    }
    
    func getDoorStatus(completion: @escaping (_ jsonDict: [String: Any]) -> Void) {
        connectDoor { [weak self] (result: [String: Any]) in
            if (result["error"] as? String) != nil {
                return completion(result)
            } else {
                guard let deviceBaseUrl = self?.deviceBaseUrl else {
                    return completion(["error": "Invalid device URL"])
                }
                self?.request(baseUrl: deviceBaseUrl, endpoint: "door/status", httpMethod: "GET") { (resultDict: [String: Any]) in
                   completion(resultDict)
                }
            }
        }
        
    }
    
    func connectDoor(completion: @escaping (_ jsonDict: [String: Any]) -> Void) {
        request(baseUrl: deviceBaseUrl, endpoint: "door/connect", httpMethod: "POST") { (resultDict: [String: Any]) in
            completion(resultDict)
        }
    }
    
    func disconnectDoor(completion: @escaping (_ jsonDict: [String: Any]) -> Void) {
        request(baseUrl: deviceBaseUrl, endpoint: "door/disconnect", httpMethod: "POST") { (resultDict: [String: Any]) in
            completion(resultDict)
        }
    }
}
