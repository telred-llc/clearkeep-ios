//
//  CKRecentListViewController.swift
//  Riot
//
//  Created by Pham Hoa on 1/8/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit
import XLActionController

protocol CKRecentListViewControllerDelegate: class {
    func recentListView(_ controller: CKRecentListViewController, didOpenRoomSettingWithRoomCellData roomCellData: MXKRecentCellData)
}

class CKRecentListViewController: MXKViewController {

    @IBOutlet weak var recentTableView: UITableView! {
        didSet {
            self.setupTableView()
        }
    }
    
    weak var delegate: CKRecentListViewControllerDelegate?

    var dataSource: [MXKRecentCellData] = []

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func reloadData(rooms: [MXKRecentCellData]) {
        self.dataSource = rooms
        self.recentTableView?.reloadData()
    }
    
    func dispayRoom(withRoomId roomId: String?, inMatrixSession matrixSession: MXSession?) {
        // Avoid multiple openings of rooms
        self.view.isUserInteractionEnabled = false

        AppDelegate.the().masterTabBarController.selectRoom(withId: roomId, andEventId: nil, inMatrixSession: matrixSession) {
            self.view.isUserInteractionEnabled = true
        }
    }
    
    func muteEditedRoomNotifications(roomData: MXKRecentCellData, mute: Bool) {
        if let room = roomData.roomSummary.room {
            startActivityIndicator()
            
            if mute {
                room.mentionsOnly({
                    self.stopActivityIndicator()
                    self.recentTableView.reloadData()
                })
            } else {
                room.allMessages({
                    self.stopActivityIndicator()
                    self.recentTableView.reloadData()
                })
            }
        } else {
            //
        }
    }
    
    func updateEditedRoomTag(roomData: MXKRecentCellData, tag: String?) {
        if let room = roomData.roomSummary.room {
            startActivityIndicator()
            
            room.setRoomTag(tag) {
                self.stopActivityIndicator()
                self.recentTableView.reloadData()
            }
        } else {
            //
        }
    }
    
    func openRoomSetting(roomData: MXKRecentCellData) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.delegate?.recentListView(self, didOpenRoomSettingWithRoomCellData: roomData)
        }
    }
}

private extension CKRecentListViewController {
    
    /**
     Setup table view
     */
    func setupTableView() {
        recentTableView.register(CKRecentItemTableViewCell.nib, forCellReuseIdentifier: CKRecentItemTableViewCell.identifier)
        recentTableView.register(CKRecentItemInvitationCell.nib, forCellReuseIdentifier: CKRecentItemInvitationCell.identifier)
        recentTableView.allowsSelection = false
        recentTableView.dataSource = self
        recentTableView.delegate = self
    }
    
    /**
     Show menu options
     */
    func showMenuOptions(roomData: MXKRecentCellData) {
        
        let actionController = YoutubeActionController.init()
        
        // Mute option
        if roomData.roomSummary.room.isMute || roomData.roomSummary.room.isMentionsOnly {
            actionController.addAction(
                Action.init(
                    ActionData.init(
                        title: String.ck_LocalizedString(key: "UnMute"),
                        image: UIImage.init(named: "notifications")!),
                    style: ActionStyle.default,
                    executeImmediatelyOnTouch: false,
                    handler: { [weak self] (action) in
                        self?.muteEditedRoomNotifications(roomData: roomData, mute: false)
            }))
        } else {
            actionController.addAction(
                Action.init(
                    ActionData.init(
                        title: String.ck_LocalizedString(key: "UnMute"),
                        image: UIImage.init(named: "notificationsOff")!),
                    style: ActionStyle.default,
                    executeImmediatelyOnTouch: false,
                    handler: { [weak self] (action) in
                        self?.muteEditedRoomNotifications(roomData: roomData, mute: true)
            }))
        }
        
        // Favourite option
        let currentTag = roomData.roomSummary.room.accountData.tags?.first?.value
        if kMXRoomTagFavourite == currentTag?.name {
            actionController.addAction(
                Action.init(
                    ActionData.init(
                        title: String.ck_LocalizedString(key: "Remove from favourite"),
                        image: UIImage.init(named: "favouriteOff")!),
                    style: ActionStyle.default,
                    executeImmediatelyOnTouch: false,
                    handler: { [weak self] (action) in
                self?.updateEditedRoomTag(roomData: roomData, tag: nil)
            }))
        } else {
            actionController.addAction(
                Action.init(
                    ActionData.init(
                        title: String.ck_LocalizedString(key: "Add to favourite"),
                        image: UIImage.init(named: "favourite")!),
                    style: ActionStyle.default,
                    executeImmediatelyOnTouch: false, handler: { [weak self] (action) in
                        self?.updateEditedRoomTag(roomData: roomData, tag: kMXRoomTagFavourite)
            }))
        }

        // Setting option
        actionController.addAction(
            Action.init(
                ActionData.init(
                    title: String.ck_LocalizedString(key: "Setting"),
                    image: UIImage.init(named: "settings_icon")!),
                style: ActionStyle.default,
                executeImmediatelyOnTouch: false,
                handler: { [weak self] (action) in
                    self?.openRoomSetting(roomData: roomData)
        }))
        
        // settings
        actionController.settings.behavior.hideOnScrollDown = true
        actionController.settings.animation.dismiss.duration = 0.4
        
        present(actionController, animated: true, completion: nil)
    }
    
    func getIndexPath(gesture: UIGestureRecognizer) -> IndexPath? {
        let touchPoint = gesture.location(in: self.view)
        return recentTableView.indexPathForRow(at: touchPoint)
    }
    
    @objc func onTableViewCellLongPress(_ gesture: UIGestureRecognizer) {
        if let selectedIndexPath = getIndexPath(gesture: gesture) {
            let selectedRoomData = dataSource[selectedIndexPath.row]
            showMenuOptions(roomData: selectedRoomData)
        }
    }
    
    @objc func onTableViewCellTap(_ gesture: UIGestureRecognizer) {
        if let selectedIndexPath = getIndexPath(gesture: gesture) {
            let selectedRoomData = dataSource[selectedIndexPath.row]
            dispayRoom(withRoomId: selectedRoomData.roomSummary.roomId, inMatrixSession: selectedRoomData.roomSummary.room.mxSession)
        }
    }
    
    /**
     Cell instance for invitation
     */
    func cellForInvitationRoom(_ indexPath: IndexPath, cellData: MXKCellData) -> CKRecentItemInvitationCell {
        
        // cell data
        let cellData = dataSource[indexPath.row]
        
        // init cell
        let cell = self.recentTableView.dequeueReusableCell(
            withIdentifier: CKRecentItemInvitationCell.identifier,
            for: indexPath) as! CKRecentItemInvitationCell
        
        // render
        cell.render(cellData)
        
        // join
        cell.joinOnPressHandler = {
            self.mainSession.joinRoom(cellData.roomSummary.roomId, completion: { (response: MXResponse<MXRoom>) in
                
                // main thread
                DispatchQueue.main.async {
                    
                    // got error
                    if let error = response.error {
                        self.showAlert(error.localizedDescription)
                    } else {
                        
                        // select room
                        AppDelegate.the()?.masterTabBarController.selectRoom(withId: cellData.roomSummary.roomId, andEventId: nil, inMatrixSession: cellData.roomSummary.mxSession)
                    }
                }
            })
        }
        
        // decline
        cell.declineOnPressHandler = {
            let invitedRoom = cellData.roomSummary.room
            invitedRoom?.leave(completion: { (response: MXResponse<Void>) in
                if let error = response.error {
                    self.showAlert(error.localizedDescription)
                }
            })
        }
        
        return cell
    }
    
    /**
     Cell for room which NOT inviation
     */
    func cellForNormalRoom(_ indexPath: IndexPath, cellData: MXKCellData) -> CKRecentItemTableViewCell {
        
        // init cell
        let cell = self.recentTableView.dequeueReusableCell(
            withIdentifier: CKRecentItemTableViewCell.identifier,
            for: indexPath) as! CKRecentItemTableViewCell
        
        // update cell
        cell.render(cellData)
        cell.selectionStyle = .none
        
        // add long press gesture to cell
        let longPress = UILongPressGestureRecognizer.init(target: self, action: #selector(onTableViewCellLongPress))
        longPress.minimumPressDuration = 0.2
        longPress.cancelsTouchesInView = false
        cell.addGestureRecognizer(longPress)
        
        // add tap gesture to cell
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(onTableViewCellTap))
        tap.cancelsTouchesInView = false
        cell.addGestureRecognizer(tap)        
        return cell
    }
    
}

extension CKRecentListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellData = dataSource[indexPath.row]
        if cellData.roomSummary.membership == MXMembership.invite{
            return self.cellForInvitationRoom(indexPath, cellData: cellData)
        } else {
            return self.cellForNormalRoom(indexPath, cellData: cellData)
        }
    }
}

extension CKRecentListViewController: UITableViewDelegate {

}
