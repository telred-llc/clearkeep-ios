//
//  CKMessageContentManagement.swift
//  Riot
//
//  Created by Pham Hoa on 2/14/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

class CKMessageContentManagement {
    class func shouldHideMessage(from event: MXEvent) -> Bool {
        switch event.eventType {
        case __MXEventTypeRoomEncrypted:
            // CK: hide e2e_blocked message ("unable to decrypt message...")
            if event.decryptionError != nil {
                return true
            }
        case __MXEventTypeRoomHistoryVisibility:
            // CK: hide "e2ee enable room..."
            return true
        case __MXEventTypeRoomEncryption:
            // CK: hide "... turned on end-to-end encryption (algorithm ...)"
            return true
        default:
            break
        }
        
        return false
    }
}
