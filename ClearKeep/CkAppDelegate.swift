//
//  CkAppDelegate.swift
//  Riot
//
//  Created by Sinbad Flyce on 11/26/18.
//  Copyright © 2018 matrix.org. All rights reserved.
//

import Foundation

@objc extension AppDelegate {
    public func useCkStoryboard(_ application: UIApplication) {
        // get theme
        let isDarkMode = RiotSettings.shared.userInterfaceTheme == ThemeType.dark.typeName
        if isDarkMode {
            themeService.switch(.dark)
            RiotSettings.shared.userInterfaceTheme = ThemeType.dark.typeName
        } else {
            themeService.switch(.light)
            RiotSettings.shared.userInterfaceTheme = ThemeType.light.typeName
        }

        self.window = UIWindow(frame: UIScreen.main.bounds)

        let storyboard = UIStoryboard(name: "MainEx", bundle: nil)        
        let initialViewController = storyboard.instantiateViewController(withIdentifier: "CkSplitViewController") as! UISplitViewController
        initialViewController.delegate = self
        
        self.window?.rootViewController = initialViewController
        self.window?.makeKeyAndVisible()
    }

    public func inviteChat(_ contact: MXKContact?, completion: ((Bool) -> Void)? ) {
        
        // is contact live?
        guard let contact = contact else {
            completion?(false)
            return
        }
        // participant id
        var participantId: String!
        
        // invite array
        var inviteArray: [String]!
        
        // 3PID
        var invite3PIDArray: [MXInvite3PID]!
        
        // has email?
        if contact.emailAddresses?.count ?? 0 > 0 {
            
            // email obj
            let email = contact.emailAddresses?.first as! MXKEmail
            
            // pick its email
            participantId = email.emailAddress
        } else {
            
            // pick display name
            participantId = contact.displayName
        }
        
        // mx tool?
        if MXTools.isEmailAddress(participantId) {
            
            // has main session
            
            guard let mainSession = self.mxSessions?.first as? MXSession else {
                completion?(false)
                return
            }
            
            // has identify server url
            if var identifyServer = mainSession.matrixRestClient?.identityServer {
                
                // is http or https?
                // trim them
                if identifyServer.hasPrefix("http://") {
                    identifyServer = identifyServer.deletingPrefix("http://")
                }
                else if identifyServer.hasPrefix("https://") {
                    identifyServer = identifyServer.deletingPrefix("https://")
                }
                
                let invite3PID = MXInvite3PID()
                invite3PID.identityServer = identifyServer
                invite3PID.medium = kMX3PIDMediumEmail
                invite3PID.address = participantId
                
                // build array
                invite3PIDArray = [invite3PID]
                
            } else {
                // make error
                let error = MXError(
                    errorCode: kMXErrCodeStringNotFound,
                    error: "No supplied identity server URL")
                
                // show error
                self.showError(asAlert: error?.createNSError())
                
                // return
                completion?(false)
                return
            }
        } else {
            
            // make invite array
            inviteArray = [participantId]
        }
        
        // create room with invitation
        if let mxSession = self.mxSessions?.first as? MXSession {
            
            // closure creating a room
            let finallyCreatedRoom = { (room: MXRoom?) -> Void in
                
                // room was created
                if let room = room {
                    
                    // callback in main thread
                    DispatchQueue.main.async {
                        completion?(true)
                        self.masterTabBarController.selectRoom(withId: room.roomId, andEventId: nil, inMatrixSession: mxSession) {}
                    }
                } else { // failing to create the room
                    DispatchQueue.main.async { completion?(false) }
                }
            }
            
            // create a direct room
            mxSession.createRoom(
                name: "Invite: \(participantId!)",
                visibility: MXRoomDirectoryVisibility.private,
                alias: nil,
                topic: nil,
                invite: inviteArray,
                invite3PID: invite3PIDArray,
                isDirect: true, preset: nil) { (response: MXResponse<MXRoom>) in
                    
                    // forward to this closure
                    finallyCreatedRoom(response.value)
                    
                    // has error
                    if let error = response.error {
                        DispatchQueue.main.async {
                            self.showError(asAlert: error)
                        }
                    }
            }
        } else {
            completion?(false)
        }
    }
    
    public func createLaunchAnimation() -> UIView? {
        
        // key windows
        if let kWindow = UIApplication.shared.keyWindow {
            
            // view
            let view = UIView(frame: kWindow.bounds)
            
            // animated launching
            let vc = CkAuthIndicatorViewController(nibName: "CkAuthIndicatorViewController", bundle: nil)
            
            // setup views
            vc.view.frame = view.bounds
            
            view.autoresizingMask = UIViewAutoresizing(rawValue: UIViewAutoresizing.flexibleWidth.rawValue | UIViewAutoresizing.flexibleHeight.rawValue)
            view.backgroundColor = UIColor.white
            view.addSubview(vc.view)
            
            // align vc.view from the left and right
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[view]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["view": vc.view]));
            
            // align vc.view from the top and bottom
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[view]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["view": vc.view]));

            // keyWindow add subview
            kWindow.addSubview(view)
            
            // return
            return view
        }
        return nil
    }
    
    // MARK - Application layout handling
    public func showNotiAlert(_ title: String?, message: String) {
        if let _ = self.errorNotification {
            self.errorNotification.dismiss(animated: false, completion: nil)
            self.errorNotification = nil
        }
        self.errorNotification = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default) { (act) in
            AppDelegate.the()?.errorNotification = nil
        }
        self.errorNotification.addAction(action)
        
        if !isErrorNotificationSuspended {
            self.errorNotification.mxk_setAccessibilityIdentifier("AppDelegateErrorAlert")
            showNotificationAlert(self.errorNotification)
        }
    }

    public func showNotificationAlert(_ alert: UIAlertController?) {
        if window.rootViewController?.presentedViewController != nil {
            alert?.popoverPresentationController?.sourceView = window.rootViewController?.presentedViewController?.view
            alert?.popoverPresentationController?.sourceRect = window.rootViewController?.presentedViewController?.view.bounds ?? CGRect.zero
            if let alert = alert {
                window.rootViewController?.presentedViewController?.present(alert, animated: true)
            }
        } else {
            alert?.popoverPresentationController?.sourceView = window.rootViewController?.view
            alert?.popoverPresentationController?.sourceRect = window.rootViewController?.view.bounds ?? CGRect.zero
            if let alert = alert {
                window.rootViewController?.present(alert, animated: true)
            }
        }
    }

    public func keyBackupStateDidChange(_ notification: Notification?) {
        guard let keyBackup = notification?.object as? MXKeyBackup else {
            return
        }
        switch keyBackup.state {
        case MXKeyBackupStateNotTrusted, MXKeyBackupStateWrongBackUpVersion, MXKeyBackupStateDisabled, MXKeyBackupStateReadyToBackUp:
            handleKeyBackupProcess(for: keyBackup)
        default:
            return
        }
    }

    @objc public func detailToContact(_ contact: MXKContact) {
        
    }

    @objc func handleKeyBackupProcess(for keyBackup: MXKeyBackup) {
        guard let _ = self.mxSessions.first as? MXSession else {
            return
        }

        CKKeyBackupRecoverManager.shared.setup(keyBackup)
        CKKeyBackupRecoverManager.shared.startBackupProcess()
    }
}
