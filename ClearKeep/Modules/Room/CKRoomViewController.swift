//
//  CKRoomViewController.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/4/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation
import MatrixKit

extension RoomViewController {
    
    @objc public func rewrite(method: String, parameters: [String: Any]) -> Bool {
        return false
    }
}

@objc final class CKRoomViewController: RoomViewController {
    
    // MARK - ENUM
    
    /**
     Rewritee
     */
    private enum Rewritee: String {
        case roomTitleView_RecognizeTapGesture  = "roomTitleView:recognizeTapGesture"
        case prepareForSegue_sender             = "prepareForSegue:sender"
    }
    
    /**
     Invokee
     */
    private enum Invokee: String {
        case updateInputToolBarViewHeight   = "updateInputToolBarViewHeight"
        case refreshRoomTitle               = "refreshRoomTitle"
        case refreshRoomInputToolbar        = "refreshRoomInputToolbar"
    }
    
    /**
     Propertee
     */
    private enum Propertee: String {
        case previewHeader = "previewHeader"
    }
    
    // MARK: - PROPERTY
    
    /**
     Preview Room Title
     */
    private var previewHeader: Any? {
        return self.value(forKey: Propertee.previewHeader.rawValue)
    }

    // MARK: - PRIVATE
    
    private func execute(execute: @escaping () -> Void) {
        DispatchQueue.main.async {
            execute()
        }
    }
    
    private func updateInputToolBarViewHeight() {
        if self.responds(to: Selector((Invokee.updateInputToolBarViewHeight.rawValue))) {
            self.perform(Selector((Invokee.updateInputToolBarViewHeight.rawValue)))
        }
    }

    private func refreshRoomTitle() {
        if self.responds(to: Selector((Invokee.refreshRoomTitle.rawValue))) {
            self.perform(Selector((Invokee.refreshRoomTitle.rawValue)))
        }
    }

    private func refreshRoomInputToolbar() {
        if self.responds(to: Selector((Invokee.refreshRoomInputToolbar.rawValue))) {
            self.perform(Selector((Invokee.refreshRoomInputToolbar.rawValue)))
        }
    }

    private func acceptJoiningRoom() {
        
        // room preview data
        guard let roomPRData = self.roomPreviewData else {
            self.joinRoom { (success: Bool) in
                if success {
                    self.refreshRoomTitle()
                }
            }
            return
        }
        
        // event and alias
        let eventId = roomPRData.eventId
        var roomIdOrAlias = roomPRData.roomId
        
        // re-assign roomIdOrAlias if it's available
        if let roomAliases = roomPRData.roomAliases, roomAliases.count > 0 {
            roomIdOrAlias = roomPRData.roomAliases.first
        }
        
        // call back room joining in success
        let onSuccessJoinedRoom = {() -> Void in
            
            // event id is available
            if let eventId = eventId {
                
                // reload room
                RoomDataSource.load(
                    withRoomId: self.roomDataSource.roomId,
                    initialEventId: eventId,
                    andMatrixSession: self.mainSession,
                    onComplete: { (rds: Any?) in
                        
                        // ux reload room
                        self.roomDataSource.finalizeInitialization()
                        if let rds = rds as? RoomDataSource {
                            rds.markTimelineInitialEvent = true
                            self.displayRoom(rds)
                            self.hasRoomDataSourceOwnership = true
                        }
                })
            } else {
                
                // reload room without event id, re-layout ux
                self.setRoomInputToolbarViewClass(RoomInputToolbarView.self)
                self.updateInputToolBarViewHeight()
                self.setRoomActivitiesViewClass(RoomActivitiesView.self)
                self.refreshRoomTitle()
                self.refreshRoomInputToolbar()
            }
        }
        
        // call back room joining in failing
        let onFailingJoinedRoom = {() -> Void in
        }
        
        // do joining room
        self.joinRoom(
            withRoomIdOrAlias: roomIdOrAlias,
            andSignUrl: roomPRData.emailInvitation.signUrl) { (success: Bool) in
                if success { onSuccessJoinedRoom() }
                else { onFailingJoinedRoom()}
        }
    }

    private func rejectJoiningRoom() {
        guard let _ = self.roomPreviewData else {
            AppDelegate.the()?.restoreInitialDisplay({})
            return
        }
        
        self.startActivityIndicator()
        self.roomDataSource.room.leave { (response: MXResponse<Void>) in
            if response.isSuccess {
                self.stopActivityIndicator()
                AppDelegate.the()?.restoreInitialDisplay({})
            } else {
                self.stopActivityIndicator()
            }
        }
    }
    
    // MARK: - OVERRIDE
    
    public override class func nib() -> UINib? {
        return UINib.init(
            nibName: String(describing: RoomViewController.self),
            bundle: Bundle(for: self))
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()        
    }
    
    public override func rewrite(method: String, parameters: [String : Any]) -> Bool {
        
        guard let rewritee =  Rewritee(rawValue: method)else {
            return false
        }
        
        switch rewritee {
            
        // recognizeTapGesture
        case .roomTitleView_RecognizeTapGesture:
            self.execute {
                self.override_roomTitleView(
                    parameters["titleView"] as? RoomTitleView,
                    recognizeTapGesture: parameters["recognizeTapGesture"] as? UITapGestureRecognizer)
            }
        
        // prepareForSegue
        case .prepareForSegue_sender:
            self.execute {
                self.override_prepare(
                    for: parameters["segue"] as! UIStoryboardSegue,
                    sender: parameters["sender"])
            }
        }
        return true
    }
}

// MARK: - MANUAL OVERRIDE EXTENSION

extension CKRoomViewController {
    
    private func override_roomTitleView(_ titleView: RoomTitleView!, recognizeTapGesture tapGestureRecognizer: UITapGestureRecognizer!) {
        if let tappedView = tapGestureRecognizer.view {
            if let prvh = self.previewHeader as? PreviewRoomTitleView {
                if tappedView == prvh.rightButton {
                    self.acceptJoiningRoom()
                } else if tappedView == prvh.leftButton {
                    self.rejectJoiningRoom()
                }
            } else {
                self.performSegue(withIdentifier: "showRoomDetails", sender: self)
            }
        }
    }
    
    private func override_prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let roomSettingsVC = segue.destination as? CKRoomSettingsViewController {
            self.dismissKeyboard()
            roomSettingsVC.initWith(
                self.roomDataSource.mxSession,
                andRoomId: self.roomDataSource.roomId)
        }
    }
}
