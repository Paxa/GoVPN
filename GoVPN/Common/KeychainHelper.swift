//
//  KeychainHelper.swift
//  GoVPN
//
//  Created by Pavel Evstigneev on 02/08/20.
//  Copyright © 2020 Colin Harris. All rights reserved.
//

import Foundation
import Cocoa
import os

class KeychainHelper {
    class func hasPassword(vpn: VPN) -> Bool {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: vpn.username,
            kSecAttrLabel as String: vpn.name,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnAttributes as String: true
        ]
        // kSecReturnData as String: true
        var item: CFTypeRef?
        SecItemCopyMatching(query as CFDictionary, &item)
        
        if let existingItem = item as? [String : Any] {
            existingItem.forEach {
                print("\($0) - \($1)")
            }
            os_log("kSecAttrAccount %s", existingItem[kSecAttrAccount as String] as? String ?? "none")
            os_log("kSecAttrLabel %s", existingItem[kSecAttrLabel as String] as? String ?? "none")
            os_log("kSecAttrDescription %s", existingItem[kSecAttrDescription as String] as? String ?? "none")
            os_log("kSecAttrService %s", existingItem[kSecAttrService as String] as? String ?? "none")
            os_log("kSecAttrApplicationTag %s", existingItem[kSecAttrApplicationTag as String] as? String ?? "none")

            return true
        }
        os_log("No keychain for vpn")
        return false
    }

    class func updatePassword(vpn: VPN, newOtp: String) -> Bool {
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: vpn.username,
            kSecAttrLabel as String: vpn.name,
        ] as CFDictionary

        let accessControlError:UnsafeMutablePointer<Unmanaged<CFError>?>? = nil
        let allocator:CFAllocator!         = kCFAllocatorDefault
        let protection:AnyObject!             = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let flags:SecAccessControlCreateFlags = SecAccessControlCreateFlags.userPresence
        
        let accessControlRef = SecAccessControlCreateWithFlags(
            allocator,
            protection,
            flags,
            accessControlError
        )

        let updateFields = [
            kSecValueData: newOtp.data(using: .utf8)!,
            //kSecAttrAccessible: kSecAttrAccessibleAlways,
            kSecAttrAccessControl: accessControlRef,
        ] as CFDictionary


        let status = SecItemUpdate(query, updateFields)

        print("Operation finished with status: \(status)")
        if status != 0 {
            let alert = NSAlert.init()
            alert.messageText = "Updating keychain \(vpn.name) failed"
            let message = SecCopyErrorMessageString(status, nil) ?? "unknown" as CFString
            alert.informativeText = "Error: \(message)\n will contrinue with long flow"
            alert.addButton(withTitle: "OK")
            alert.runModal()
            
        }
        return true
    }
}
