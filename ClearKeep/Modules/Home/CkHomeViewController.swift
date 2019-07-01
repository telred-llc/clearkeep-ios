//
//  CkHomeViewController.swift
//  Riot
//
//  Created by Sinbad Flyce on 12/28/18.
//  Copyright © 2018 matrix.org. All rights reserved.
//

import Foundation
import MatrixKit
import Parchment

final class CkHomeViewController: CKRecentListViewController {
    
    // MARK: Properties
    var avatarTapGestureRecognizer: UITapGestureRecognizer?
    var recentsDataSource: RecentsDataSource?
    var missedDiscussionsCount: Int = 0
    
    // MARK: LifeCycle
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
        
        // Listen to the user info did changed
        NotificationCenter.default.addObserver(self, selector: #selector(userInfoDidChanged(_:)), name: NSNotification.Name.mxkAccountUserInfoDidChange, object: nil) 
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.setupNavigationBar()

        if let recentsDataSource = self.recentsDataSource {
            recentsDataSource.areSectionsShrinkable = false
            recentsDataSource.setDelegate(self, andRecentsDataSourceMode: RecentsDataSourceModeHome)
        }

        // Observe server sync at room data source level too
        NotificationCenter.default.addObserver(self, selector: #selector(onMatrixSessionChange), name: NSNotification.Name(rawValue: kMXKRoomDataSourceSyncStatusChanged), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: kMXKRoomDataSourceSyncStatusChanged), object: nil)
    }
    
    // MARK: Setup view
    
    func setupNavigationBar() {
        guard let masterTabbar = AppDelegate.the()?.masterTabBarController else { return }
        // setup title
        masterTabbar.navigationItem.title = nil
        
        // setup left menu
        setupLeftMenu(navigationItem: masterTabbar.navigationItem)
        
        // setup right menu
        setupRightMenu(navigationItem: masterTabbar.navigationItem)
    }
    
    func setupLeftMenu(navigationItem: UINavigationItem) {

        guard let session = AppDelegate.the()?.mxSessions.first as? MXSession else {
            navigationItem.leftBarButtonItem = nil
            return
        }
        
        var leftMenuView: CkAvatarTopView! = navigationItem.leftBarButtonItem?.customView as? CkAvatarTopView
        if leftMenuView == nil {
            leftMenuView = CkAvatarTopView.instance()
            
            // add tap gesture to leftMenuView
            avatarTapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(clickedOnLeftMenuItem))
            avatarTapGestureRecognizer!.cancelsTouchesInView = false
            leftMenuView.addGestureRecognizer(avatarTapGestureRecognizer!)
        }
        
        if let myUser = session.myUser {
            
            // set uri avatar
            leftMenuView.setAvatarUri(myUser.avatarUrl, userId: myUser.userId, session: self.mainSession)
            
            // status
            switch myUser.presence {
            case MXPresenceOnline:
                leftMenuView.setStatus(online: true)
            default:
                leftMenuView.setStatus(online: false)
            }
            
            navigationItem.leftBarButtonItem = UIBarButtonItem.init(customView: leftMenuView)
        } else {
            navigationItem.leftBarButtonItem = nil
        }
    }
    
    func setupRightMenu(navigationItem: UINavigationItem) {
        let newChatItem = UIBarButtonItem.init(image: UIImage.init(named: "ic_new_chat"), style: .plain, target: self, action: #selector(clickedOnRightMenuItem))
        navigationItem.rightBarButtonItem = newChatItem
    }
    
    // MARK: Action
    
    @objc func userInfoDidChanged(_ noti: NSNotification) {
        let account = MXKAccountManager.shared()?.accounts.first
        if let account = account, let accountUserId = noti.object as? String, account.mxCredentials.userId == accountUserId {
            guard let masterTabbar = AppDelegate.the()?.masterTabBarController else { return }
            setupLeftMenu(navigationItem: masterTabbar.navigationItem)
        }
    }
    
    @objc func clickedOnLeftMenuItem() {
        self.showSettingViewController()
    }
    
    @objc func clickedOnRightMenuItem() {
        self.showDirectChatVC()
    }
    
    func showSettingViewController() {
        // initialize vc from xib
        let vc = CKAccountProfileViewController(
            nibName: CKAccountProfileViewController.nibName,
            bundle: nil)
        
        // import mx session and room id
        vc.importSession(self.mxSessions)
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc public func displayList(_ aRecentsDataSource: MXKRecentsDataSource!) {

        // sure this one
        guard let recentsDataSource = aRecentsDataSource else {
            return
        }
        
        // Cancel registration on existing dataSource if any
        if self.recentsDataSource != nil {
            self.recentsDataSource!.delegate = nil
            
            // Remove associated matrix sessions
            let mxSessions = self.mxSessions as? [MXSession]
            mxSessions.flatMap({ return $0 })?.forEach({ (mxSession) in
                self.removeMatrixSession(mxSession)
            })
        }
     
        self.recentsDataSource = recentsDataSource as? RecentsDataSource
        self.recentsDataSource?.delegate = self
        
        // Report all matrix sessions at view controller level to update UI according to sessions state
        let mxSessions = recentsDataSource.mxSessions as? [MXSession]
        mxSessions.flatMap({ return $0 })?.forEach({ (mxSession) in
            self.addMatrixSession(mxSession)
        })
    }
    
    /**
     Process direct chatting
     */
    func processDirectChat(_ userId: String, completion: ((Bool) -> Void)?) {
        
        // account is ok
        if let acc = MXKAccountManager.shared()?.activeAccounts.first {
            
            // session is ok
            if let mxSession = acc.mxSession {
                
                // closure creating a room
                let finallyCreatedRoom = { (room: MXRoom?) -> Void in
                    
                    // room was created
                    if let room = room {
                        
                        // callback in main thread
                        DispatchQueue.main.async {
                            completion?(true)
                            AppDelegate.the().masterTabBarController.selectRoom(withId: room.roomId, andEventId: nil, inMatrixSession: mxSession) {}
                        }
                    } else { // failing to create the room
                        DispatchQueue.main.async { completion?(false) }
                    }
                }
                
                // Aha, there is an existing direct room
                if let room =  mxSession.directJoinedRoom(withUserId: userId) {
                    
                    // forward to this closure
                    finallyCreatedRoom(room)
                } else {
                    
                    // build invitees
                    let invitees = [userId]
                    
                    // create a direct room
                    mxSession.createRoom(
                        name: nil,
                        visibility: MXRoomDirectoryVisibility.private,
                        alias: nil,
                        topic: nil,
                        invite: invitees,
                        invite3PID: nil,
                        isDirect: true, preset: nil) { (response: MXResponse<MXRoom>) in
                            
                            // vars
                            let room = response.value
                            var isFinallyEncryption = false
                            
                            room?.enableEncryption(
                                withAlgorithm: kMXCryptoMegolmAlgorithm,
                                completion: { (response2: MXResponse<Void>) in
                                    
                                    // finish creating room
                                    if isFinallyEncryption == false {
                                        finallyCreatedRoom(room)
                                    }
                                    
                                    // set on this var
                                    isFinallyEncryption = true
                            })

                    }
                }
            }
        }
    }
    
    /**
     Process direct calling
     */
    func processDirectCall(_ userId: String, completion: ((Bool) -> Void)?) {
        
        // account is ok
        if let acc = MXKAccountManager.shared()?.activeAccounts.first {
            
            // session is ok
            if let mxSession = acc.mxSession {
                
                // closure creating a room
                let finallyCreatedRoom = { (room: MXRoom?) -> Void in
                    
                    // room was created
                    if let room = room {
                        
                        // callback in main thread
                        DispatchQueue.main.async {
                            completion?(true)
                            AppDelegate.the().masterTabBarController.selectRoom(withId: room.roomId, andEventId: nil, inMatrixSession: mxSession) {
                                let roomVC = AppDelegate.the().masterTabBarController.currentRoomViewController
                                if roomVC?.isSupportCallOption() == true && roomVC?.isCallingInRoom() != true {
                                    
                                    // Delay for pushing completed
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                                        roomVC?.handleCallToRoom(nil)
                                    })
                                }
                            }
                        }
                    } else { // failing to create the room
                        DispatchQueue.main.async { completion?(false) }
                    }
                }
                
                // Aha, there is an existing direct room
                if let room =  mxSession.directJoinedRoom(withUserId: userId) {
                    
                    // forward to this closure
                    finallyCreatedRoom(room)
                } else {
                    
                    // build invitees
                    let invitees = [userId]
                    
                    // create a direct room
                    mxSession.createRoom(
                        name: nil,
                        visibility: MXRoomDirectoryVisibility.private,
                        alias: nil,
                        topic: nil,
                        invite: invitees,
                        invite3PID: nil,
                        isDirect: true, preset: nil) { (response: MXResponse<MXRoom>) in
                            
                            // forward to this closure
                            finallyCreatedRoom(response.value)
                    }
                }
            }
        }
    }
    
    // MARK: - CREATE DIRECT AND ROOM CHAT
    
    /**
     Show direct chat creating controller
     */
    func showDirectChatVC() {
        // init
        let nvc = CKRoomDirectCreatingViewController.instanceNavigation { (vc: MXKViewController) in

            // is class?
            if let vc = vc as? CKRoomDirectCreatingViewController {

                // setup vc
                vc.delegate = self
                vc.importSession(self.mxSessions)
            }
        }

        self.present(nvc, animated: true, completion: nil)
    }
    
    /**
     Show room creating controller
     */
    func showRoomChatVC() {

        // init
        let nvc = CKRoomCreatingViewController.instanceNavigation { (vc: MXKViewController) in

            // is class?
            if let vc = vc as? CKRoomCreatingViewController {

                // importing session
                vc.importSession(self.mxSessions)
            }
        }

        self.present(nvc, animated: true, completion: nil)
    }

}

extension CkHomeViewController {
    @objc override func onMatrixSessionChange() {
        super.onMatrixSessionChange()
        
        let mxSessions = self.mxSessions as? [MXSession]
        mxSessions.flatMap({ return $0 })?.forEach({ (mxSession) in
            if MXKRoomDataSourceManager.sharedManager(forMatrixSession: mxSession)?.isServerSyncInProgress == true {
                // sync is in progress for at least one data source, keep running the loading wheel
                self.activityIndicator?.startAnimating()
                return
            }
        })
    }
}

extension CkHomeViewController: MXKDataSourceDelegate {
    
    func cellViewClass(for cellData: MXKCellData!) -> MXKCellRendering.Type! {
        return CKRecentItemTableViewCell.self
    }
    
    func cellReuseIdentifier(for cellData: MXKCellData!) -> String! {
        return CKRecentItemTableViewCell.defaultReuseIdentifier()
    }
    
    @objc public func dataSource(_ dataSource: MXKDataSource?, didCellChange changes: Any?) {
        self.reloadDataSource()
        
        // reflect Badge
        AppDelegate.the()?.masterTabBarController.reflectingBadges()
    }
    
    func dataSource(_ dataSource: MXKDataSource!, didAddMatrixSession mxSession: MXSession!) {
        self.addMatrixSession(mxSession)
    }
    
    func dataSource(_ dataSource: MXKDataSource!, didRemoveMatrixSession mxSession: MXSession!) {
        self.removeMatrixSession(mxSession)
    }
    
    private func reloadDataSource() {
        var rooms: [[MXKRecentCellData]] = []
        
        if var roomsArray = self.recentsDataSource?.conversationCellDataArray as? [MXKRecentCellData] {
            if let invitesArray = self.recentsDataSource?.invitesCellDataArray as? [MXKRecentCellData] {
                for invite in invitesArray.reversed() {
                    if invite.roomSummary.isDirect == false {
                        roomsArray.insert(invite, at: 0)
                    }
                }
            }
            rooms.append(roomsArray)
        } else {
            rooms.append([])
        }
        
        if var peopleArray = self.recentsDataSource?.peopleCellDataArray as? [MXKRecentCellData] {
            if let invitesArray = self.recentsDataSource?.invitesCellDataArray as? [MXKRecentCellData] {
                for invite in invitesArray.reversed() {
                    if invite.roomSummary.isDirect == true {
                        peopleArray.insert(invite, at: 0)
                    }
                }
            }
            rooms.append(peopleArray) 
        } else {
            rooms.append([])
        }
        self.missedDiscussionsCount = rooms.reduce(0, { $0 + $1.filter({ $0.roomSummary.membership == MXMembership.invite || $0.hasUnread || $0.notificationCount > 0 }).count })
        self.reloadData(rooms: rooms)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let roomSettingsVC = segue.destination as? CKRoomSettingsViewController, let roomCellData = sender as? MXKRecentCellData {
            roomSettingsVC.initWith(roomCellData.roomSummary.mxSession, andRoomId: roomCellData.roomSummary.roomId)
        }
    }
}

extension CkHomeViewController: CKRecentListViewControllerDelegate {
    
    func recentListView(_ controller: CKRecentListViewController, didOpenRoomSettingWithRoomCellData roomCellData: MXKRecentCellData) {
        
        // init nvc
        let nvc = CKRoomSettingsViewController.instanceNavigation { (vc: MXKTableViewController) in
            
            // completed vc
            if let vc = vc as? CKRoomSettingsViewController {
                
                // init
                vc.initWith(roomCellData.roomSummary.mxSession, andRoomId: roomCellData.roomSummary.roomId)
            }
        }
        
        // present
        self.present(nvc, animated: true, completion: nil)
    } 
    
    /**
     Delegate of Recent List view controller
     */
    func recentListViewDidTapStartChat(_ section: Int) {
        if section == SectionRecent.room.rawValue {
            self.showRoomChatVC()
        } else if section == SectionRecent.direct.rawValue {
            self.showDirectChatVC()
        }
    }
}

// MARK: - CKRoomDirectCreatingViewControllerDelegate

extension CkHomeViewController: CKRoomDirectCreatingViewControllerDelegate {

    /**
     In the CKRoomDirectCreatingViewController, if you select a contact to direct chat.
     Then, it should be callback this function
     */
    func roomDirectCreating(withUserId userId: String, completion: ((Bool) -> Void)?) {
        self.processDirectChat(userId, completion: completion)
    }
}

extension CkHomeViewController: CKContactListViewControllerDelegate {

    func contactListCreating(withUserId userId: String, completion: ((Bool) -> Void)?) {
        self.processDirectChat(userId, completion: completion)
    }
}
