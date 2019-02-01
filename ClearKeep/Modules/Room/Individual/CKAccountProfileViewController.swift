//
//  CKAccountProfileViewController.swift
//  Riot
//
//  Created by Hiếu Nguyễn on 1/23/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

class CKAccountProfileViewController: MXKViewController {
    // MARK: - OUTLET
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - ENUM
    
    private enum Section: Int {
        case avatar  = 0
        case action  = 1
        case detail  = 2
        
        static var count: Int { return 3}
    }
    
    // MARK: - CLASS
    
    public class func instance() -> CKAccountProfileViewController? {
        let instance = CKAccountProfileViewController(nibName: self.nibName, bundle: nil)
        return instance
    }
    
    // MARK: - PROPERTY
    
    private var request: MXHTTPOperation!
    private var myUser: MXMyUser?

    // Observers
    private var removedAccountObserver: Any?
    private var accountUserInfoObserver: Any?
    private var pushInfoUpdateObserver: Any?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.myUser = self.getMyUser()
        self.finalizeLoadView()
        
        // Add observer to handle removed accounts
        removedAccountObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.mxkAccountManagerDidRemoveAccount, object: nil, queue: OperationQueue.main, using: { notif in
            // Refresh table to remove this account
            self.refreshData()
        })
        
        // Add observer to handle accounts update
        accountUserInfoObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.mxkAccountUserInfoDidChange, object: nil, queue: OperationQueue.main, using: { notif in
            
            self.stopActivityIndicator()
            self.refreshData()
        })
        
        // Add observer to push settings
        pushInfoUpdateObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.mxkAccountPushKitActivityDidChange, object: nil, queue: OperationQueue.main, using: { notif in
            
            self.stopActivityIndicator()
            self.refreshData()
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = "Profile"
    }
    
    deinit {
        if request != nil {
            request.cancel()
            request = nil
        }
        
        if pushInfoUpdateObserver != nil {
            NotificationCenter.default.removeObserver(pushInfoUpdateObserver!)
            pushInfoUpdateObserver = nil
        }
        
        if accountUserInfoObserver != nil {
            NotificationCenter.default.removeObserver(accountUserInfoObserver!)
            accountUserInfoObserver = nil
        }
        
        if removedAccountObserver != nil {
            NotificationCenter.default.removeObserver(removedAccountObserver!)
            removedAccountObserver = nil
        }
    }
    
    override func onMatrixSessionStateDidChange(_ notif: Notification?) {
        // Check whether the concerned session is a new one which is not already associated with this view controller.
        if let mxSession = notif?.object as? MXSession {
            if mxSession.state == MXSessionStateInitialised && self.mxSessions.contains(where: { ($0 as? MXSession) == mxSession }) == true {
                // Store this new session
                addMatrixSession(mxSession)
            } else {
                super.onMatrixSessionStateDidChange(notif)
            }
        }
        self.refreshData()
    }
    
    // MARK: - PRIVATE
    
    private func finalizeLoadView() {
        
        // register cells
        self.tableView.register(CKAccountProfileAvatarCell.nib, forCellReuseIdentifier: CKAccountProfileAvatarCell.identifier)
        self.tableView.register(CKAccountProfileActionCell.nib, forCellReuseIdentifier: CKAccountProfileActionCell.identifier)
        self.tableView.register(CKAccountProfileInfoCell.nib, forCellReuseIdentifier: CKAccountProfileInfoCell.identifier)
        self.tableView.allowsSelection = false
    }
    
    private func getMyUser() -> MXMyUser? {
        let session = AppDelegate.the()?.mxSessions.first as? MXSession
        if let myUser = session?.myUser {
            return myUser
        }
        return nil
    }

    private func refreshData() {
        self.myUser = self.getMyUser()
        self.tableView.reloadData()
    }
    
    private func cellForAvatarPersonal(atIndexPath indexPath: IndexPath) -> CKAccountProfileAvatarCell {
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: CKAccountProfileAvatarCell.identifier, for: indexPath) as? CKAccountProfileAvatarCell {
            
            cell.nameLabel.text = myUser?.displayname
            
            if let myUser = self.myUser {
                
                //status
                switch myUser.presence {
                case MXPresenceOnline:
                    cell.settingStatus(online: true)
                default:
                    cell.settingStatus(online: false)
                }
                
                // Display Avatar
                let defaultAvatar = AvatarGenerator.generateAvatar(forMatrixItem: myUser.userId, withDisplayName: myUser.displayname)
                if let avatarUrl = self.mainSession.matrixRestClient.url(ofContent: myUser.avatarUrl) {
                    cell.setAvatarImageUrl(urlString: avatarUrl, previewImage: defaultAvatar)
                } else {
                    cell.avaImage.image = defaultAvatar
                }
            } else {
                cell.settingStatus(online: false)
                cell.avaImage.image = nil
            }

            return cell
        }
        return CKAccountProfileAvatarCell()
    }
    
    private func cellForAction(atIndexPath indexPath: IndexPath) -> CKAccountProfileActionCell {
        
        // dequeue cell
        if let cell = tableView.dequeueReusableCell(
            withIdentifier: CKAccountProfileActionCell.identifier,
            for: indexPath) as? CKAccountProfileActionCell {
            
            // action
            cell.editHandler = {
                
                if let nvc = self.navigationController {
                    let vc = CKAccountProfileEditViewController.instance()
                    vc.importSession(self.mxSessions)
                    nvc.pushViewController(vc, animated: true)
                    
                } else {
                
                    let nvc = CKAccountProfileEditViewController.instanceNavigation(completion: { (vc) in
                        vc.importSession(self.mxSessions)
                    })
                    self.present(nvc, animated: true, completion: nil)
                }
            }
            
            cell.settingHandler = {
                let settingVC = UIStoryboard.init(name: "MainEx", bundle: nil).instantiateViewController(withIdentifier: "SettingsViewController")
                self.navigationController?.pushViewController(settingVC, animated: true)
            }
            
            return cell
        }
        return CKAccountProfileActionCell()
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
                cell.contentLabel.text = myUser?.displayname
            } else if indexPath.row == 1 {
                cell.titleLabel.text = "User ID"
                cell.contentLabel.text = myUser?.userId
            } else {
                cell.titleLabel.text = nil
                cell.contentLabel.text = nil
            }

            return cell
        }
        
        return CKAccountProfileInfoCell()
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
        }
    }    
}

// MARK: - UITableViewDelegate

extension CKAccountProfileViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let section = Section(rawValue: indexPath.section) else { return 0}
        switch section {
        case .avatar:
            return 250
            
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

extension CKAccountProfileViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // sure to work
        guard let section = Section(rawValue: section) else { return 0 }
        
        // number rows in case
        switch section {
        case .avatar: return 1
        case .action: return 1
        case .detail: return 2
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
        }
    }
}

