//
//  CKRecentListViewController.swift
//  Riot
//
//  Created by Pham Hoa on 1/8/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit
import XLActionController
import FloatingPanel

protocol CKRecentListViewControllerDelegate: class {
    func recentListView(_ controller: CKRecentListViewController, didOpenRoomSettingWithRoomCellData roomCellData: MXKRecentCellData)
    func recentListViewDidTapStartChat(_ class: AnyClass)
}

class CKRecentListViewController: MXKViewController {

    @IBOutlet weak var recentTableView: UITableView! {
        didSet {
            self.setupTableView()
        }
    }
    
    weak var delegate: CKRecentListViewControllerDelegate?

    var dataSource: [MXKRecentCellData] = []
    
    var fpc: FloatingPanelController!
    var isAddview = false
    let viewbg = UIView()

    var isEmpty: Bool {
        return (self.dataSource.count == 0)
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func reloadData(rooms: [MXKRecentCellData]) {
        
        // update source
        self.dataSource = rooms
        
        // separator
        if self.isEmpty { self.recentTableView.separatorStyle = .none }
        else { self.recentTableView.separatorStyle = .singleLine }
        
        // reload tb
        self.recentTableView?.reloadData()        
    }
    
    func displayRoom(withRoomId roomId: String?, inMatrixSession matrixSession: MXSession?) {
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
    
    private func showLeaveRoom(roomData: MXKRecentCellData) {
        
        // alert obj
        let alert = UIAlertController(
            title: "Are you sure to leave room?",
            message: nil,
            preferredStyle: .actionSheet)
        
        // leave room
        alert.addAction(UIAlertAction(title: "Leave", style: .default , handler:{ (_) in
            
            // spin
            self.startActivityIndicator()
            
            // do leaving room
            if let room = roomData.roomSummary?.room {
                
                // leave
                room.leave(completion: { (response: MXResponse<Void>) in
                    
                    // main thread
                    DispatchQueue.main.async {
                        
                        // spin
                        self.stopActivityIndicator()
                        
                        // error
                        if let error = response.error {
                            
                            // alert
                            self.showAlert(error.localizedDescription)
                        } else { // ok
                            self.dismiss(animated: false, completion: nil)
                        }
                    }
                })
            }
        }))
        
        // cancel
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:{ (_) in
        }))
        
        // present
        self.present(alert, animated: true, completion: nil)
    }
}

private extension CKRecentListViewController {
    
    /**
     Setup table view
     */
    func setupTableView() {
        recentTableView.register(CKRecentItemTableViewCell.nib, forCellReuseIdentifier: CKRecentItemTableViewCell.identifier)
        recentTableView.register(CKRecentItemInvitationCell.nib, forCellReuseIdentifier: CKRecentItemInvitationCell.identifier)
        recentTableView.register(CKRecentItemFirstChatCell.nib, forCellReuseIdentifier: CKRecentItemFirstChatCell.identifier)
        recentTableView.register(CKRecentItemFirstFavouriteCell.nib, forCellReuseIdentifier: CKRecentItemFirstFavouriteCell.identifier)
        recentTableView.allowsSelection = false
        recentTableView.dataSource = self
        recentTableView.delegate = self
    }
    
    /**
     Show menu options
     */
    func showMenuOptions(roomData: MXKRecentCellData) {
        fpc = FloatingPanelController()
        
        fpc.delegate = self
        let contentVC = CKMenuRoomViewController.init(nibName: "CKMenuRoomViewController", bundle: nil)
        fpc.set(contentViewController: contentVC)
        fpc.isRemovalInteractionEnabled = true // Optional: Let it removable by a swipe-down
        
        contentVC.callBackCKRecentListVC = { (type) in
            switch type {
            case .unMute:
                self.muteEditedRoomNotifications(roomData: roomData, mute: true)
            case .mute:
                self.muteEditedRoomNotifications(roomData: roomData, mute: false)
            case .removeFromFavourite:
                self.updateEditedRoomTag(roomData: roomData, tag: nil)
            case .addToFavourite:
                self.updateEditedRoomTag(roomData: roomData, tag: kMXRoomTagFavourite)
            case .setting:
                self.openRoomSetting(roomData: roomData)
            case .leave:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                    self.showLeaveRoom(roomData: roomData)
                })
            }
            
            self.dismiss(animated: true, completion: nil)
            self.viewbg.isHidden = true
            self.isAddview = false
            guard let masterTabbar = AppDelegate.the()?.masterTabBarController else { return }
            masterTabbar.navigationController?.navigationBar.isUserInteractionEnabled = true
            masterTabbar.navigationController?.navigationBar.alpha = 1.0
        }
        
        // Mute option
        if roomData.roomSummary.room.isMute || roomData.roomSummary.room.isMentionsOnly {
            contentVC.mute = .mute
        } else {
            contentVC.mute = .unMute
        }
        
        // Favourite option
        let currentTag = roomData.roomSummary.room.accountData.tags?.first?.value
        if kMXRoomTagFavourite == currentTag?.name {
            contentVC.favourite = .removeFromFavourite
        } else {
            contentVC.favourite = .addToFavourite
        }
        
        self.present(fpc, animated: true, completion: nil)
        
    }
    
    func getIndexPath(gesture: UIGestureRecognizer) -> IndexPath? {
        let touchPoint = gesture.location(in: self.recentTableView)
        return recentTableView.indexPathForRow(at: touchPoint)
    }
    
    @objc func onTableViewCellLongPress(_ gesture: UIGestureRecognizer) {
        
        // do nothing
        if self.isEmpty {
            return
        }
        
        // try to do more
        if let selectedIndexPath = getIndexPath(gesture: gesture) {
            let selectedRoomData = dataSource[selectedIndexPath.row]
            if isAddview == false {
                viewbg.isHidden = false
                viewbg.frame = UIApplication.shared.keyWindow!.frame
                viewbg.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.4)
                isAddview = true
                let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(bgTapped(tapGestureRecognizer:)))
                viewbg.isUserInteractionEnabled = true
                viewbg.addGestureRecognizer(tapGestureRecognizer)

                if self.parent?.parent?.parent?.isKind(of: CkHomeViewController.self) == true {
                    self.parent?.parent?.parent?.view.addSubview(viewbg)
                } else if self.isKind(of: CKRecentListViewController.self) {
                    self.view.addSubview(viewbg)
                }
            }
            showMenuOptions(roomData: selectedRoomData)
        }
    }
    
    // Action
    
    @objc func bgTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        self.dismiss(animated: true, completion: nil)
        viewbg.isHidden = true
        isAddview = false
        guard let masterTabbar = AppDelegate.the()?.masterTabBarController else { return }
        masterTabbar.navigationController?.navigationBar.isUserInteractionEnabled = true
        masterTabbar.navigationController?.navigationBar.alpha = 1.0

    }
    
    @objc func onTableViewCellTap(_ gesture: UIGestureRecognizer) {
        
        // do nothing
        if self.isEmpty {
            return
        }
        
        // try to do more
        if let selectedIndexPath = getIndexPath(gesture: gesture) {
            let selectedRoomData = dataSource[selectedIndexPath.row]
            displayRoom(withRoomId: selectedRoomData.roomSummary.roomId, inMatrixSession: selectedRoomData.roomSummary.room.mxSession)
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
            
            // session
            var ms: MXSession! = self.mainSession
            
            // is nil?
            if ms == nil {
                
                // Get the first session of AppDelegate
                ms = AppDelegate.the()?.mxSessions.first as? MXSession
            }
            
            guard let session = ms else {
                self.showAlert("Occur an error. Please try to join chat later.")
                return
            }
            
            session.joinRoom(cellData.roomSummary.roomId, completion: { (response: MXResponse<MXRoom>) in
                
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
        // cell.render(cellData)
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
    
    /**
     Cell for first chatting
     */
    func cellForStartChat(_ indexPath: IndexPath) -> CKRecentItemFirstChatCell {
        
        // init cell
        let cell = self.recentTableView.dequeueReusableCell(
            withIdentifier: CKRecentItemFirstChatCell.identifier,
            for: indexPath) as! CKRecentItemFirstChatCell

        // style
        cell.selectionStyle = .none

        // action
        cell.startChattingHanlder = {
            self.delegate?.recentListViewDidTapStartChat(self.classForCoder)
        }
        
        // change text        
        if self.isKind(of: CKDirectMessagePageViewController.self) {
            cell.startChatButton.setTitle("Start Direct Chat", for: .normal)
        } else if self.isKind(of: CKRoomPageViewController.self) {
            cell.startChatButton.setTitle("Start Room Chat", for: .normal)
        }
        
        return cell
    }
    
    /**
     Cell for first chatting
     */
    func cellForFirstFavourite(_ indexPath: IndexPath) -> CKRecentItemFirstFavouriteCell {
        
        // init cell
        let cell = self.recentTableView.dequeueReusableCell(
            withIdentifier: CKRecentItemFirstFavouriteCell.identifier,
            for: indexPath) as! CKRecentItemFirstFavouriteCell
        
        // style
        cell.selectionStyle = .none
        
        return cell
    }
}

extension CKRecentListViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // direct or room
        return dataSource.count == 0 ? 1 : dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // empty? and not favourite?
        if self.isEmpty {
            
            // fav
            if self.isKind(of: CKFavouriteViewController.self) {
                return self.cellForFirstFavourite(indexPath)
            }
            
            // s-chat
            return self.cellForStartChat(indexPath)
        } else {
            
            // direct & room?
            let cellData = dataSource[indexPath.row]
            if cellData.roomSummary.membership == MXMembership.invite {
                return self.cellForInvitationRoom(indexPath, cellData: cellData)
            } else {
                return self.cellForNormalRoom(indexPath, cellData: cellData)
            }
        }
    }
}

extension CKRecentListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? CKRecentItemInvitationCell {
            cell.updateUI()
        }
        else if let cell = cell as? CKRecentItemTableViewCell {
            let cellData = dataSource[indexPath.row]
            cell.render(cellData)
        }
    }
}

extension CKRecentListViewController {
    
    override func startActivityIndicator() {
        // TODO: this is a temporary fix
    }
}

extension CKRecentListViewController: FloatingPanelControllerDelegate {
    
    func floatingPanelDidEndDragging(_ vc: FloatingPanelController, withVelocity velocity: CGPoint, targetPosition: FloatingPanelPosition) {
        if targetPosition == .tip {
            self.dismiss(animated: true, completion: nil)
            isAddview = false
        }
    }
    
    func floatingPanelDidChangePosition(_ vc: FloatingPanelController) {
        if vc.position == .hidden {
            fpc.fp_dismiss(animated: false)
            viewbg.isHidden = true
            isAddview = false
            guard let masterTabbar = AppDelegate.the()?.masterTabBarController else { return }
            masterTabbar.navigationController?.navigationBar.isUserInteractionEnabled = true
            masterTabbar.navigationController?.navigationBar.alpha = 1.0
        } else {
            viewbg.isHidden = false
            guard let masterTabbar = AppDelegate.the()?.masterTabBarController else { return }
            masterTabbar.navigationController?.navigationBar.isUserInteractionEnabled = false
            masterTabbar.navigationController?.navigationBar.alpha = 0.6
        }
    }
}
