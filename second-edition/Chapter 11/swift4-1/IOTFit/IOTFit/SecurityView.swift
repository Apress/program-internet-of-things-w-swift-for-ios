//
//  SecurityView.swift
//  IOTFit
//
//  Created by Ahmed Bakir on 2018/09/11.
//  Copyright © 2018 Ahmed Bakir. All rights reserved.
//

import UIKit
import LocalAuthentication

enum AuthenticationType : String {
    case faceID
    case touchID
    case password
    case notAvailable
}
protocol SecurityViewDelegate {
    func didFinishWithAuthenticationType(_ type: AuthenticationType)
    func didFinishWithError(description: String)
    func needsInitialPassword()
    func didSavePassword(success: Bool)
}

class SecurityView: UIView {

    @IBOutlet var unlockButton: UIButton?
    @IBOutlet var passwordTextField: UITextField?
    
    let context = LAContext()
    var accessControl: SecAccessControl?
    
    let ACCOUNT_NAME: String = "IOTFit"
    
    var delegate: SecurityViewDelegate?
    var authenticationType: AuthenticationType?

    override func awakeFromNib() {
        super.awakeFromNib()
        commonInit()
    }
    
    private func commonInit() {
        
        let error: ErrorPointer = nil
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: error) {
            switch (context.biometryType) {
            case LABiometryType.faceID:
                authenticationType = AuthenticationType.faceID
                unlockButton?.setTitle("Use Face ID", for: .normal)
            case LABiometryType.touchID:
                authenticationType = AuthenticationType.touchID
                unlockButton?.setTitle("Use Touch ID", for: .normal)
            default:
                authenticationType = AuthenticationType.notAvailable
                unlockButton?.isEnabled = false
                unlockButton?.setTitleColor(UIColor.gray, for: .normal)
            }
        } else {
            NSLog("Biometrics unavailable on device")
            unlockButton?.isEnabled = false
            unlockButton?.setTitleColor(UIColor.gray, for: .normal)
        }
        
        accessControl = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenUnlocked, .userPresence, nil)
    }
    
    func checkPasswordExistence() {
        
        guard let accessControl = accessControl else { return }
        
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                           kSecAttrAccount as String: ACCOUNT_NAME,
                                           kSecMatchLimit as String: kSecMatchLimitOne,
                                           kSecReturnAttributes as String: true,
                                           kSecReturnData as String: true,
                                           kSecAttrAccessControl as String: accessControl as Any,
                                           kSecUseAuthenticationContext as String: context,
        ]
        
        let queryStatus = SecItemCopyMatching(query as CFDictionary, nil)
        
        if queryStatus != errSecSuccess {
            delegate?.needsInitialPassword()
        } else {
            NSLog("Password has already been set")
        }
    }
    
    func savePassword(password: String) {
        
        guard let accessControl = accessControl,
              let passwordData = password.data(using: String.Encoding.utf8) else { return }
        
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: ACCOUNT_NAME,
                                    kSecAttrAccessControl as String: accessControl as Any,
                                    kSecUseAuthenticationContext as String: context,
                                    kSecValueData as String: passwordData]
        
        let queryStatus = SecItemAdd(query as CFDictionary, nil)
        
        if queryStatus == errSecSuccess {
            delegate?.didSavePassword(success: true)
        } else {
            NSLog("Error saving passcode: \(queryStatus)")
            delegate?.didSavePassword(success: false)
        }
    }
    
    private func getSavedPassword() -> String? {
        
        guard let accessControl = accessControl else { return nil }
        
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: ACCOUNT_NAME,
                                    kSecMatchLimit as String: kSecMatchLimitOne,
                                    kSecReturnAttributes as String: true,
                                    kSecAttrAccessControl as String: accessControl as Any,
                                    kSecUseAuthenticationContext as String: context,
                                    kSecReturnData as String: true
        ]
        var keychainItemRef: CFTypeRef?
        
        let queryStatus = SecItemCopyMatching(query as CFDictionary, &keychainItemRef)
        
        guard queryStatus == errSecSuccess,
            let keychainItem = keychainItemRef as? [String: Any],
            let passwordData = keychainItem[kSecValueData as String] as? Data,
            let password = String(data: passwordData, encoding: String.Encoding.utf8)
            else {
                return nil
        }
        return password
    }

    @IBAction func validatePassword(sender: UITextField) {
        guard let input = sender.text,
              let savedPassword = getSavedPassword(),
              input == savedPassword else {
                delegate?.didFinishWithError(description: "Invalid password")
                return
        }
        delegate?.didFinishWithAuthenticationType(.password)
    }
    
    @IBAction func validateBiometrics(sender: UIButton) {
    
        passwordTextField?.resignFirstResponder()
        
        let permissionString = "Unlock with biometrics to reveal workout data"

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: permissionString) { [weak self] (success: Bool, error: Error?) in
            
            guard let authenticationType = self?.authenticationType else { return }
            
            if success == true {
                self?.delegate?.didFinishWithAuthenticationType(authenticationType)
            } else {
                self?.delegate?.didFinishWithError(description: error.debugDescription)
            }
        }
    }
}

extension SecurityView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        validatePassword(sender: textField)
        return true
    }
}
