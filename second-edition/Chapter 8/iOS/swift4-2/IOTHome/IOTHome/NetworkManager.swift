//
//  NetworkManager.swift
//  IOTHome
//
//  Created by Ahmed Bakir on 2018/08/26.
//  Copyright © 2018 Ahmed Bakir. All rights reserved.
//

import Foundation

class NetworkManager: NSObject, URLSessionDelegate {
    
    static let shared = NetworkManager(urlString: "https://theta3dev.local:4443")
    
    let baseUrl: URL
    
    init(urlString: String) {
        guard let baseUrl = URL(string: urlString) else {
            fatalError("Invalid URL string")
        }
        
        self.baseUrl = baseUrl
    }

    func request(endpoint: String, httpMethod: String, completion: @escaping (_ jsonDict: [String: Any]) -> Void) {
        
        guard let url = URL(string: endpoint, relativeTo: baseUrl) else {
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
    
    func getTemperature(completion: @escaping (_ jsonDict: [String: Any]) -> Void) {
        request(endpoint: "temperature", httpMethod: "GET") { (resultDict: [String: Any]) in
            completion(resultDict)
        }
    }
    
    func getDoorStatus(completion: @escaping (_ jsonDict: [String: Any]) -> Void) {
        connectDoor { [weak self] (result: [String: Any]) in
            if (result["error"] as? String) != nil {
                return completion(result)
            } else {
                self?.request(endpoint: "door/status", httpMethod: "GET") { (resultDict: [String: Any]) in
                   completion(resultDict)
                }
            }
        }
        
    }
    
    func connectDoor(completion: @escaping (_ jsonDict: [String: Any]) -> Void) {
        request(endpoint: "door/connect", httpMethod: "POST") { (resultDict: [String: Any]) in
            completion(resultDict)
        }
    }
    
    func disconnectDoor(completion: @escaping (_ jsonDict: [String: Any]) -> Void) {
        request(endpoint: "door/disconnect", httpMethod: "POST") { (resultDict: [String: Any]) in
            completion(resultDict)
        }
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
}
