//
//  CKMessageContentManagement.swift
//  Riot
//
//  Created by Pham Hoa on 2/14/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

class CKMessageContentManagement {
    class func shouldHideMessage(from event: MXEvent, inRoomState roomState: MXRoomState! ) -> Bool {
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
        case __MXEventTypeRoomMember:
            // is event membership?
            if event.content.keys.contains("membership") {
                
                if let v = event.content["membership"] as? String {
                    if v == "join" || v == "invite" {
                        return false
                    }
                }                
                return true
            }
            // not
            return false
        case __MXEventTypeRoomName:
            // created date existing?
            if let crd = roomState?.createdDate {
                // < 5 second
                if event.date.timeIntervalSince(crd) < 5 {
                    return true
                }
            }
            return false
        case __MXEventTypeRoomTopic:
            // created date existing?
            if let crd = roomState?.createdDate {
                // < 5 second
                if event.date.timeIntervalSince(crd) < 5 {
                    return true
                }
            }
            return false
        case __MXEventTypeReaction:
            return false
        default:
            break
        }
        
        return false
    }
}
