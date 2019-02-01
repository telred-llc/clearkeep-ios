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
        case avatar  = 0
        case action  = 1
        case detail  = 2
        
        static var count: Int { return 3}
    }
    
    // MARK: - CLASS
    
    public class func instance() -> CKOtherProfileViewController? {
        let instance = CKOtherProfileViewController(nibName: self.nibName, bundle: nil)
        return instance
    }
    
    // MARK: - PROPERTY
    
    /**
     MX Room
     */
    public var mxMember: MXRoomMember!
    private var request: MXHTTPOperation!
    
    // Observers to manage ongoing conference call banner
    private var kMXCallStateDidChangeObserver: Any?
    private var kMXCallManagerConferenceStartedObserver: Any?
    private var kMXCallManagerConferenceFinishedObserver: Any?
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        self.tableView.allowsSelection = false
    }
    
    private func cellForAvatarPersonal(atIndexPath indexPath: IndexPath) -> CKAccountProfileAvatarCell {
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: CKAccountProfileAvatarCell.identifier, for: indexPath) as? CKAccountProfileAvatarCell {
            
            cell.nameLabel.text = mxMember.displayname
            
            if let avtURL = self.mainSession.matrixRestClient.url(ofContent: mxMember.avatarUrl ) {
                cell.setAvatarImageUrl(urlString: avtURL, previewImage: nil)
            } else {
                cell.avaImage.image = AvatarGenerator.generateAvatar(forText: mxMember.userId)
            }
            
            //status
            let session = AppDelegate.the()?.mxSessions.first as? MXSession
            if let myUser = session?.myUser {
                switch myUser.presence {
                case MXPresenceOnline:
                    cell.settingStatus(online: true)
                default:
                    cell.settingStatus(online: false)
                }
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
                cell.contentLabel.text = mxMember.displayname
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
}

// MARK: - UITableViewDelegate

extension CKOtherProfileViewController: UITableViewDelegate {
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

extension CKOtherProfileViewController: UITableViewDataSource {
    
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
