//
//  Keychain.swift
//  Using Keychain Services
//
//  Created by Gheorghe Chesler on 6/15/15.
//  Copyright © 2015 Devatelier. All rights reserved.
//

import Foundation
import Security

public class Keychain {
    public class func set(key: String, value: String) -> Bool {
        if let data = value.dataUsingEncoding(NSUTF8StringEncoding) {
            SecItemDelete(deleteQuery(key))
            return SecItemAdd(updateQuery(key, value: data), nil) == noErr
        }
        return false
    }
    
    public class func get(key: String) -> NSString? {
        let query = searchQuery(key)
        if let data = getData(query) {
            return NSString(data: data, encoding: NSUTF8StringEncoding)
        }
        return nil
    }
    
    public class func getData(query: CFDictionaryRef) -> NSData? {
        var response: AnyObject?
        let status = withUnsafeMutablePointer(&response) {
            SecItemCopyMatching(query, UnsafeMutablePointer($0))
        }
        return status == noErr && response != nil
            ? response as! NSData?
            : nil
    }
    
    public class func delete(key: String) -> Bool {
        return SecItemDelete( deleteQuery(key) ) == noErr
    }
    
    public class func clear() -> Bool {
        if SecItemDelete([(kSecClass as String) : kSecClassGenericPassword]) == noErr {
            print("all passwords deleted")
        }
        return SecItemDelete( clearQuery() ) == noErr
    }
    
    private class func updateQuery(key: String, value: NSData) -> CFDictionaryRef {
        return NSMutableDictionary(
            objects: [ kSecClassGenericPassword, key, value ],
            forKeys: [ String(kSecClass), String(kSecAttrAccount), String(kSecValueData) ]
        )
    }
    private class func deleteQuery(key: String) -> CFDictionaryRef {
        return NSMutableDictionary(
            objects: [ kSecClassGenericPassword, key ],
            forKeys: [ String(kSecClass), String(kSecAttrAccount) ]
        )
    }
    private class func searchQuery(key: String) -> CFDictionaryRef {
        return NSMutableDictionary(
            objects: [ kSecClassGenericPassword, key, kCFBooleanTrue, kSecMatchLimitOne ],
            forKeys: [ String(kSecClass), String(kSecAttrAccount), String(kSecReturnData), String(kSecMatchLimit) ]
        )
    }
    private class func clearQuery() -> CFDictionaryRef {
        return [ (kSecClass as String) : kSecClassGenericPassword ]
    }
    
}