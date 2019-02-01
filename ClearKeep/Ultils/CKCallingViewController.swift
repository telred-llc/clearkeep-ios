//
//  CKCallingViewController.swift
//  Riot
//
//  Created by Pham Hoa on 2/2/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKCallViewController: CallViewController {
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: CallViewController.nibName, bundle: Bundle.init(for: CKCallViewController.self))
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func call(_ call: MXCall, didEncounterError error: Error) {
        let nsError = error as NSError
        
        if nsError._domain == MXEncryptingErrorDomain && nsError._code == Int(MXEncryptingErrorUnknownDeviceCode.rawValue) {
            // There are unknown devices -> call anyway

            let unknownDevices = nsError.userInfo[MXEncryptingErrorUnknownDeviceDevicesKey] as? MXUsersDevicesMap<MXDeviceInfo>

            // Acknowledge the existence of all devices

            startActivityIndicator()
            self.mainSession?.crypto?.setDevicesKnown(unknownDevices) { [weak self] in
                
                self?.stopActivityIndicator()
                
                // Retry the call
                if call.isIncoming {
                    call.answer()
                } else {
                    call.call(withVideo: call.isVideoCall)
                }
            }
        } else {
            super.call(call, didEncounterError: error)
        }
    }
}
