//
//  CKRecentListViewController.swift
//  Riot
//
//  Created by Pham Hoa on 1/8/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit
import XLActionController

class CKRecentListViewController: MXKViewController {

    @IBOutlet weak var recentTableView: UITableView! {
        didSet {
            self.setupTableView()
        }
    }
    
    var dataSource: [MXKRecentCellData] = []
    let kCellNibName = "CKRecentItemTableViewCell"

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
        let roomSettingsVC = RoomSettingsViewController.init()
        roomSettingsVC.initWith(roomData.roomSummary.room.mxSession, andRoomId: roomData.roomSummary.roomId)
        AppDelegate.the()?.masterTabBarController.show(roomSettingsVC, sender: nil)
    }
}

private extension CKRecentListViewController {
    func setupTableView() {
        recentTableView.register(UINib.init(nibName: kCellNibName, bundle: nil), forCellReuseIdentifier: kCellNibName)
        recentTableView.allowsSelection = false
        recentTableView.dataSource = self
        recentTableView.delegate = self
    }
    
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
}

extension CKRecentListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kCellNibName, for: indexPath) as! CKRecentItemTableViewCell
        let cellData = dataSource[indexPath.row]
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

extension CKRecentListViewController: UITableViewDelegate {

}
