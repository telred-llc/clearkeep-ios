//
//  CKOtherProfileViewController.swift
//  Riot
//
//  Created by Hiếu Nguyễn on 1/23/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

class CKOtherProfileViewController: MXKViewController {
    // MARK: - OUTLET
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - ENUM
    
    private enum Section: Int {
        case avatar     = 0
        case action     = 1
        case detail     = 2
        case setAdmin   = 3
        
        static var memberCount: Int { return 3}
        static var adminCount: Int { return 4}
    }
    
    // MARK: - CLASS
    
    public class func instance() -> CKOtherProfileViewController? {
        let instance = CKOtherProfileViewController(nibName: self.nibName, bundle: nil)
        return instance
    }
    
    // MARK: - PROPERTY
    
    private var request: MXHTTPOperation!
    
    // Observers to manage ongoing conference call banner
    private var kMXCallStateDidChangeObserver: Any?
    private var kMXCallManagerConferenceStartedObserver: Any?
    private var kMXCallManagerConferenceFinishedObserver: Any?
    
    /**
     members Listener
     */
    private var membersListener: Any!
    
    /**
     MX Room
     */
    public var mxMember: MXRoomMember!
    public var mxRoomPowerLevels: MXRoomPowerLevels?
    public var mxRoom: MXRoom?
    private var myUser: MXMyUser?
    private let kCkRoomAdminLevel = 100

    /**
     When you want this controller always behavior a presenting controller, set true it
     */
    internal var isForcedPresenting = false

    override func viewDidLoad() {
        super.viewDidLoad()
        myUser = getMyUser()
        self.finalizeLoadView()
    }
    deinit {
        if request != nil {
            request.cancel()
            request = nil
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = "Profile"
    }
    
    // MARK: - PRIVATE
    
    private func finalizeLoadView() {
        
        // register cells
        self.tableView.register(CKAccountProfileAvatarCell.nib, forCellReuseIdentifier: CKAccountProfileAvatarCell.identifier)
        self.tableView.register(CKOtherProfileActionCell.nib, forCellReuseIdentifier: CKOtherProfileActionCell.identifier)
        self.tableView.register(CKAccountProfileInfoCell.nib, forCellReuseIdentifier: CKAccountProfileInfoCell.identifier)
        self.tableView.register(CKAssignAdminButtonTableViewCell.nib, forCellReuseIdentifier:CKAssignAdminButtonTableViewCell.identifier)
        self.tableView.allowsSelection = false
        
        if self.isForcedPresenting {
            // Setup close button item
            let closeItemButton = UIBarButtonItem.init(
                image: UIImage(named: "ic_x_close"),
                style: .plain,
                target: self, action: #selector(clickedOnBackButton(_:)))
            
            // set nv items
            self.navigationItem.leftBarButtonItem = closeItemButton
        }
        
        // invoke timeline event
        self.liveTimelineEvents()
        
        // Update user state
        self.updateUserState()
    }
    
    private func cellForAvatarPersonal(atIndexPath indexPath: IndexPath) -> CKAccountProfileAvatarCell {
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: CKAccountProfileAvatarCell.identifier, for: indexPath) as? CKAccountProfileAvatarCell {
            
            let dispn = mxMember?.displayname ?? (mxMember?.userId?.components(separatedBy: ":").first ?? "Unknown")
            
            cell.nameLabel.text = dispn
            cell.setAvatarUri(
                mxMember.avatarUrl,
                identifyText: dispn,
                session: self.mainSession)
            
            // Is admin
            if let mxMember = mxMember, let powerLevels = mxRoomPowerLevels, powerLevels.powerLevelOfUser(withUserID: mxMember.userId) == kCkRoomAdminLevel {
                cell.adminStatusView.isHidden = false
            } else {
                cell.adminStatusView.isHidden = true
            }
            
            //status
            if let mxMember = mxMember,
                let presence = self.mainSession?.user(withUserId: mxMember.userId)?.presence {
                switch presence {
                case MXPresenceOnline:
                    cell.settingStatus(online: true)
                default:
                    cell.settingStatus(online: false)
                }
            } else {
                cell.settingStatus(online: false)
            }
            return cell
        }
        return CKAccountProfileAvatarCell()
    }
    
    private func cellForAction(atIndexPath indexPath: IndexPath) -> CKOtherProfileActionCell {
        
        // dequeue cell
        if let cell = tableView.dequeueReusableCell(
            withIdentifier: CKOtherProfileActionCell.identifier,
            for: indexPath) as? CKOtherProfileActionCell {
            
            cell.messageHandler = {
                if let userId = self.mxMember.userId {
                    self.displayDirectRoom(userId: userId)
                }
            }
            
            cell.callHandler = {
                if let userId = self.mxMember.userId {
                    self.callToRoom(userId: userId)
                }
            }
            
            return cell
        }
        return CKOtherProfileActionCell()
    }
    
    private func cellForInfoPersonal(atIndexPath indexPath: IndexPath) -> CKAccountProfileInfoCell {
        
        if let cell = tableView.dequeueReusableCell(
            withIdentifier: CKAccountProfileInfoCell.identifier,
            for: indexPath) as? CKAccountProfileInfoCell {
            
            
            // Title
            cell.titleLabel.font = CKAppTheme.mainLightAppFont(size: 17)
            cell.titleLabel.textColor = #colorLiteral(red: 0.4352941176, green: 0.431372549, blue: 0.4509803922, alpha: 1)

            if indexPath.row == 0 {
                cell.titleLabel.text = "Display name"
                cell.contentLabel.text = mxMember?.displayname ?? (mxMember?.userId?.components(separatedBy: ":").first ?? "Unknown")
            } else if indexPath.row == 1 {
                cell.titleLabel.text = "User ID"
                cell.contentLabel.text = mxMember.userId
            } else {
                cell.titleLabel.text = nil
                cell.contentLabel.text = nil
            }
            
            return cell
        }
        return CKAccountProfileInfoCell()
    }
    
    private func cellForSetAdmin(indexPath: IndexPath) -> CKAssignAdminButtonTableViewCell {
        if let cell = tableView.dequeueReusableCell(
            withIdentifier: CKAssignAdminButtonTableViewCell.identifier,
            for: indexPath) as? CKAssignAdminButtonTableViewCell {
            
            cell.assignAdminHandler = { [weak self] in
                self?.setUserToAdmin()
            }
            
            return cell
        }
        
        return CKAssignAdminButtonTableViewCell()
    }
    
    private func titleForHeader(atSection section: Int) -> String {
        guard let section = Section(rawValue: section) else { return ""}
        
        switch section {
        case .avatar:
            return ""
        case .action:
            return ""
        case .detail:
            return ""
        case .setAdmin:
            return ""
        }
    }
    
    private func displayDirectRoom(userId: String) {
        // progress stop
        self.startActivityIndicator()

        // Avoid multiple openings of rooms
        self.view.isUserInteractionEnabled = false
        AppDelegate.the().masterTabBarController?.homeViewController.processDirectChat(userId, completion: { (success) in
            self.view.isUserInteractionEnabled = true
            
            // progress stop
            self.stopActivityIndicator()
            
            if success {
                self.dismiss(animated: false, completion: nil)
                AppDelegate.the().masterTabBarController?.navigationController?.popToRootViewController(animated: false)
            }
        })
    }
    
    private func callToRoom(userId: String) {
        // progress stop
        self.startActivityIndicator()
        
        // Avoid multiple openings of rooms
        self.view.isUserInteractionEnabled = false
        AppDelegate.the().masterTabBarController?.homeViewController.processDirectCall(userId, completion: { (success) in
            self.view.isUserInteractionEnabled = true
            
            // progress stop
            self.stopActivityIndicator()
            
            if success {
                self.dismiss(animated: false, completion: nil)
                AppDelegate.the().masterTabBarController?.navigationController?.popToRootViewController(animated: false)
            }
        })
    }
    
    // Get current logined user
    private func getMyUser() -> MXMyUser? {
        let session = AppDelegate.the()?.mxSessions.first as? MXSession
        if let myUser = session?.myUser {
            return myUser
        }
        return nil
    }
    
    // Check if it's able to set user to
    private func canSetUserToAdmin() -> Bool {
        guard let roomPowerLevels = mxRoomPowerLevels, let myUser = myUser, mxRoom != nil else {
            return false
        }
        
        let currentPowerLevel = roomPowerLevels.powerLevelOfUser(withUserID: mxMember.userId)
        let myUserPowerLevel = roomPowerLevels.powerLevelOfUser(withUserID: myUser.userId)
        
        // don't have permision to set room admin or user had alreadly been admin
        if myUserPowerLevel < kCkRoomAdminLevel || currentPowerLevel == kCkRoomAdminLevel {
            return false
        }
        
        return true
    }
    
    private func updateUserState() {
        // room state
        guard let mxRoom = mxRoom else {
            return
        }
        mxRoom.state { [weak self] (state: MXRoomState?) in
            guard let weakSelf = self else {
                return
            }
            // Update power levels
            weakSelf.mxRoomPowerLevels = state?.powerLevels
            DispatchQueue.main.async {
                weakSelf.tableView.reloadData()
            }
        }
    }
    
    private func liveTimelineEvents() {
        guard let mxRoom = mxRoom else {
            return
        }
        // event of types
        let eventsOfTypes = [MXEventType.roomPowerLevels]
        
        // list members
        mxRoom.liveTimeline { (liveTimeline: MXEventTimeline?) in
            
            // guard
            guard let liveTimeline = liveTimeline else {
                return
            }
            
            // timeline listen to events
            self.membersListener = liveTimeline.listenToEvents(eventsOfTypes, { [weak self] (event: MXEvent, direction: MXTimelineDirection, state: MXRoomState) in
                
                // direction
                if direction == MXTimelineDirection.forwards, let weakSelf = self {
                    // If powerlevels has been changed, reload user status
                    weakSelf.updateUserState()
                }
            })
        }
    }
    
    // MARK: - ACTION
    @objc func clickedOnBackButton(_ sender: Any?) {
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - UITableViewDelegate

extension CKOtherProfileViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let section = Section(rawValue: indexPath.section) else { return 0}
        switch section {
        case .avatar:
            return 250
        case .setAdmin:
            return 100
        default:
            return 60
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView.init()
        view.backgroundColor = UIColor.white
        return view
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView.init()
        view.backgroundColor = UIColor.white
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10
    }
    
}

// MARK: - UITableViewDataSource

extension CKOtherProfileViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        let sectionCount = canSetUserToAdmin() ? Section.adminCount : Section.memberCount
        return sectionCount
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // sure to work
        guard let section = Section(rawValue: section) else { return 0 }
        
        // number rows in case
        switch section {
        case .avatar: return 1
        case .action: return 1
        case .detail: return 2
        case .setAdmin: return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // sure to work
        guard let section = Section(rawValue: indexPath.section) else { return CKAccountProfileBaseCell() }
        
        switch section {
        case .avatar:
            
            // account profile avatar cell
            return cellForAvatarPersonal(atIndexPath: indexPath)
        case .action:
            
            // account profile action cell
            return cellForAction(atIndexPath: indexPath)
        case .detail:
            return cellForInfoPersonal(atIndexPath: indexPath)
        case .setAdmin:
            return cellForSetAdmin(indexPath: indexPath)
        }
    }
}

extension CKOtherProfileViewController {
    
    // Set cu
    func setUserToAdmin() {
        guard let roomPowerLevels = mxRoomPowerLevels, let myUser = myUser, let room = mxRoom else {
            return
        }
        
        let currentPowerLevel = roomPowerLevels.powerLevelOfUser(withUserID: mxMember.userId)
        let myUserPowerLevel = roomPowerLevels.powerLevelOfUser(withUserID: myUser.userId)
        
        // don't have permision to set room admin
        if myUserPowerLevel < kCkRoomAdminLevel {
            return
        }
        
        if currentPowerLevel != kCkRoomAdminLevel {
            self.startActivityIndicator()
            // Set user to admin
            room.setPowerLevel(ofUser: mxMember.userId, powerLevel: kCkRoomAdminLevel) { [weak self](response: MXResponse<Void>) in
                guard let weakSelf = self else {
                    return
                }
                
                weakSelf.stopActivityIndicator()
                
                if response.isSuccess {
                    print("Assign admin  ")
                } else {
                    if let error = response.error {
                        weakSelf.showAlert(error.localizedDescription)
                    } else {
                        weakSelf.showAlert("Occur an unknow error")
                    }
                }
            }
        } else {
            self.updateUserState()
        }
    }
}
