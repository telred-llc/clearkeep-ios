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
        case detail     = 1
        case setAdmin   = 2
        
        static var memberCount: Int { return 2}
        static var adminCount: Int { return 3}
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

    private let disposeBag = DisposeBag()

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
        self.tableView.register(CKUserProfileDetailCell.nib, forCellReuseIdentifier: CKUserProfileDetailCell.identifier)
        self.tableView.register(CKAssignAdminButtonTableViewCell.nib, forCellReuseIdentifier:CKAssignAdminButtonTableViewCell.identifier)
        self.tableView.allowsSelection = false
        
        addCustomBackButton()
        
        if self.isForcedPresenting {
            // Setup close button item
            let closeItemButton = UIBarButtonItem.init(
                image: UIImage(named: "ic_x_close"),
                style: .plain,
                target: self, action: #selector(clickedOnBackButton(_:)))
            
            // set nv items
            closeItemButton.tintColor = themeService.attrs.navBarTintColor
            self.navigationItem.leftBarButtonItem = closeItemButton
        }
        
        // invoke timeline event
        self.liveTimelineEvents()
        
        // Update user state
        self.updateUserState()

        self.bindingTheme()
        
        self.setupItemBarButton()
        
    }
    
    private func bindingTheme() {
        // Binding navigation bar color
        themeService.attrsStream.subscribe(onNext: { [weak self] (theme) in
            self?.defaultBarTintColor = themeService.attrs.navBarBgColor
            self?.barTitleColor = themeService.attrs.navBarTintColor
        }).disposed(by: disposeBag)

        themeService.rx
            .bind({ $0.primaryBgColor }, to: view.rx.backgroundColor, tableView.rx.backgroundColor)
            .disposed(by: disposeBag)
    }

    private func cellForAvatarPersonal(atIndexPath indexPath: IndexPath) -> CKAccountProfileAvatarCell {
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: CKAccountProfileAvatarCell.identifier, for: indexPath) as? CKAccountProfileAvatarCell {
            
            let dispn = mxMember?.displayname ?? (mxMember?.userId?.components(separatedBy: ":").first ?? "Unknown")
            
            cell.currentDisplayName = dispn
            cell.isCanEditDisplayName = false
            
            cell.setAvatarUri(
                mxMember.avatarUrl,
                identifyText: dispn,
                session: self.mainSession)
            
            // Is admin
            if let mxMember = mxMember, let powerLevels = mxRoomPowerLevels, powerLevels.powerLevelOfUser(withUserID: mxMember.userId) == kCkRoomAdminLevel {
                cell.isAdminPower = true
            } else {
                cell.isAdminPower = false
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

            cell.theme.backgroundColor = themeService.attrStream{ $0.primaryBgColor }

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

            cell.contentView.backgroundColor = UIColor.clear
            cell.theme.backgroundColor = themeService.attrStream{ $0.secondBgColor }
            cell.messageButton.theme.titleColor(from: themeService.attrStream{ $0.primaryTextColor }, for: .normal)
            cell.callButton.theme.titleColor(from: themeService.attrStream{ $0.primaryTextColor }, for: .normal)

            return cell
        }
        return CKOtherProfileActionCell()
    }
    
    private func cellForInfoPersonal(atIndexPath indexPath: IndexPath) -> CKUserProfileDetailCell {
        
        if let cell = tableView.dequeueReusableCell(
            withIdentifier: CKUserProfileDetailCell.identifier,
            for: indexPath) as? CKUserProfileDetailCell {
            switch indexPath.row {
            case 0:
                cell.bindingData(icon: #imageLiteral(resourceName: "user_profile"), content: mxMember.userId)
            case 1:
                cell.bindingData(icon: #imageLiteral(resourceName: "location_profile"), content: "")
            case 2:
                cell.bindingData(icon: #imageLiteral(resourceName: "phone_profile"), content: "")
            default:
                break
            }
            
            return cell
        }
        
        return CKUserProfileDetailCell()
    }
    
    private func cellForSetAdmin(indexPath: IndexPath) -> CKAssignAdminButtonTableViewCell {
        if let cell = tableView.dequeueReusableCell(
            withIdentifier: CKAssignAdminButtonTableViewCell.identifier,
            for: indexPath) as? CKAssignAdminButtonTableViewCell {
            
            cell.assignAdminHandler = { [weak self] in
                if let weakSelf = self {
                    weakSelf.setUserToAdmin()
                }
            }

            cell.theme.backgroundColor = themeService.attrStream{ $0.primaryBgColor }
            return cell
        }
        
        return CKAssignAdminButtonTableViewCell()
    }
    
    private func titleForHeader(atSection section: Int) -> String {
        guard let section = Section(rawValue: section) else { return ""}
        
        switch section {
        case .avatar:
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
            return UITableViewAutomaticDimension
        case .setAdmin:
            return 100
        default:
            return UITableViewAutomaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView.init()
        view.theme.backgroundColor = themeService.attrStream{ $0.tblHeaderBgColor }
        return view
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView.init()
        view.theme.backgroundColor = themeService.attrStream{ $0.tblHeaderBgColor }
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
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
        case .detail: return 3
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


// MARK: Config Bar Button Message + Calling
extension CKOtherProfileViewController {
    
    private func setupItemBarButton() {
        
        let message = UIBarButtonItem(image: #imageLiteral(resourceName: "message_profile").withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(handlerMessageRoom))
        message.tintColor = themeService.attrs.primaryTextColor
        
        let calling = UIBarButtonItem(image: #imageLiteral(resourceName: "calling_profile").withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(handlerCallRoom))
        calling.tintColor = themeService.attrs.primaryTextColor
        
        navigationItem.rightBarButtonItems = [calling, message]
    }
    
    
    @objc
    private func handlerMessageRoom() {
        if let userId = self.mxMember.userId {
            self.displayDirectRoom(userId: userId)
        }
    }
    
    @objc
    private func handlerCallRoom() {
        if let userId = self.mxMember.userId {
            self.callToRoom(userId: userId)
        }
    }
}
