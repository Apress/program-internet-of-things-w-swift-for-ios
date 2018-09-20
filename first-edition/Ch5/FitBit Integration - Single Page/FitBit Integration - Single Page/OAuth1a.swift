//
//  OAuth1a.swift
//  FitBit Integration - Single Page
//
//  Created by Gheorghe Chesler on 4/15/15.
//  Copyright (c) 2015 DevAtelier. All rights reserved.
//
import Foundation

class OAuth1a {
    var signatureMethod: String = "HMAC-SHA1"
    var oauthVersion: String = "1.0"
    var oauthConsumerKey: String!
    var oauthConsumerSecret: String!
    var oauthToken: String!
    var oauthTokenSecret: String!
    
    required init (oauthParams: NSDictionary) {
        oauthConsumerKey = oauthParams.objectForKey("oauth_consumer_key") as! String
        oauthConsumerSecret = oauthParams.objectForKey("oauth_consumer_secret") as! String
        oauthToken = oauthParams.objectForKey("oauth_token") as! String
        oauthTokenSecret = oauthParams.objectForKey("oauth_token_secret") as! String
    }
    
    func randomStringWithLength (len : Int) -> String {
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let randomString : NSMutableString = NSMutableString(capacity: len)
        
        for (var i=0; i < len; i++){
            let length = UInt32(letters.length)
            let rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
        }
        return randomString as String
    }
    
    func signRequest (request: NSMutableURLRequest, urlParameters: [String:String]!=[:], signUrl: String!=nil) {
        let timeStamp = String(format:"%d", Int(NSDate().timeIntervalSince1970))
        let nonce = randomStringWithLength(11)
        var baseUrl: String
        if signUrl == nil {
            baseUrl = (request.valueForKey("URL") as! NSURL).absoluteString
            print("REQUEST URL: " + baseUrl)
        }
        else {
            baseUrl = signUrl
            print("SIGN URL: " + signUrl)
        }
        print("TIMESTAMP: " + timeStamp)
        print("NONCE: " + nonce)
        
        // The signing params need to be sorted alphabetically
        var signatureParams: [String:String] = [:]
        for (key, value) in urlParameters {
            signatureParams.updateValue(value, forKey: key)
        }
        signatureParams.updateValue(oauthConsumerKey, forKey: "oauth_consumer_key")
        signatureParams.updateValue(nonce, forKey: "oauth_nonce")
        signatureParams.updateValue(signatureMethod, forKey: "oauth_signature_method")
        signatureParams.updateValue(timeStamp, forKey: "oauth_timestamp")
        
        if oauthToken != nil {
            signatureParams.updateValue(oauthToken, forKey: "oauth_token")
            request.setValue(oauthToken, forHTTPHeaderField: "oauth_token")
        }
        signatureParams.updateValue(oauthVersion, forKey: "oauth_version")
        
        let normalizedParameters: String = asURLString(signatureParams)
        
        let signatureBaseString: String = [
            request.HTTPMethod,
            baseUrl.escapeUrl(),
            normalizedParameters.escapeUrl()
            ].joinWithSeparator("&")
        // the key is the concatenated values (each first encoded per Parameter Encoding)
        // of the Consumer Secret and Token Secret, separated by an ‘&’ character (ASCII code 38) even if empty
        let signKey = oauthConsumerSecret.escapeUrl() + "&" + oauthTokenSecret.escapeUrl()
        let signature = signatureBaseString.hmac(HMACAlgorithm.SHA1, key: signKey)
        
        print("SIGNATURE STRING: " +  signatureBaseString)
        print("SIGNATURE KEY: " +  signKey)
        print("SIGNATURE: " +  signature)
        
        // This exact order has to be preserved
        let header: OAuth1aHeader = OAuth1aHeader(name: "OAuth")
        header.add("oauth_consumer_key", value: oauthConsumerKey)
        header.add("oauth_nonce", value: nonce)
        header.add("oauth_signature", value: signature)
        header.add("oauth_signature_method", value: signatureMethod)
        header.add("oauth_timestamp", value: timeStamp)
        header.add("oauth_token", value: oauthToken)
        header.add("oauth_version", value: oauthVersion)
        let hParams = header.asString()
        
        print("HEADER: Authorization: " + hParams)
        request.setValue(hParams, forHTTPHeaderField: "Authorization")
    }
    
    func asURLString (inputData: [String:String]!=[:]) -> String {
        var params: [String] = []
        for (key, value) in inputData {
            params.append( [ key.escapeUrl(), value.escapeUrl()].joinWithSeparator("=" ))
        }
        params = params.sort{ $0 < $1 }
        return params.joinWithSeparator("&")
    }
        
    func signTempAccessToken (request: NSMutableURLRequest) {
        // This request does not use the URL for signing, but rather the path oauth/request_token
        let requestUrl = request.valueForKey("URL") as? NSURL
        var urlPath: String = requestUrl!.path!
        urlPath = String(urlPath.characters.dropFirst())
        signRequest(request, signUrl: urlPath)
    }
    
    class OAuth1aHeader {
        var hName: String!
        var params: Array<String>!
        required init (name: String) {
            params = Array<String>()
            hName = name
        }
        func add (key: String, value: String) {
            params.append(key + "=\"" + value.escapeUrl() + "\"")
        }
        func asString () -> String {
            let hParams: String = params.joinWithSeparator(", ")
            return hName + " " + hParams
        }
    }
}