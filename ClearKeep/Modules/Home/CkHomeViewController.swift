//
//  CkHomeViewController.swift
//  Riot
//
//  Created by Sinbad Flyce on 12/28/18.
//  Copyright © 2018 matrix.org. All rights reserved.
//

import Foundation
import MatrixKit

final class CkHomeViewController: MXKViewController {
    
    var avatarTapGestureRecognizer: UITapGestureRecognizer?
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Listen to the direct rooms list
        NotificationCenter.default.addObserver(self, selector: #selector(didDirectRoomsChange(_:)), name: NSNotification.Name.mxSessionDirectRoomsDidChange, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar()
    }
    
    func setupNavigationBar() {
        guard let masterTabbar = AppDelegate.the()?.masterTabBarController else { return }
        // setup title
        masterTabbar.navigationItem.title = nil
        
        // setup left menu
        setupLeftMenu()
    }
    
    func setupLeftMenu() {
        guard let masterTabbar = AppDelegate.the()?.masterTabBarController else { return }

        guard let session = AppDelegate.the()?.mxSessions.first as? MXSession else {
            masterTabbar.navigationItem.leftBarButtonItem = nil
            return
        }
        
        var leftMenuView: CkAvatarTopView! = masterTabbar.navigationItem.leftBarButtonItem?.customView as? CkAvatarTopView
        if leftMenuView == nil {
            leftMenuView = CkAvatarTopView.instance()
            
            // add tap gesture to leftMenuView
            avatarTapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(clickedOnLeftMenuItem))
            avatarTapGestureRecognizer!.cancelsTouchesInView = false
            leftMenuView.addGestureRecognizer(avatarTapGestureRecognizer!)
        }
        
        if let myUser = session.myUser {
            // display name
            leftMenuView.membernameLabel.text = myUser.displayname
            
            // avatar
            let defaultAvatar = AvatarGenerator.generateAvatar(forMatrixItem: myUser.userId, withDisplayName: myUser.displayname)
            if let avatarUrl = myUser.avatarUrl,
                let urlString = session.matrixRestClient.url(ofContentThumbnail: avatarUrl, toFitViewSize: leftMenuView.imgAvatar.frame.size, with: MXThumbnailingMethodCrop) {
                leftMenuView.setAvatarImageUrl(urlString: urlString, previewImage: defaultAvatar)
            } else {
                leftMenuView.setImage(image: defaultAvatar)
            }
            
            // status
            switch myUser.presence {
            case MXPresenceOnline:
                leftMenuView.setStatus(online: true)
            default:
                leftMenuView.setStatus(online: false)
            }
            
            masterTabbar.navigationItem.leftBarButtonItem = UIBarButtonItem.init(customView: leftMenuView)
        } else {
            masterTabbar.navigationItem.leftBarButtonItem = nil
        }
    }
    
    @objc func didDirectRoomsChange(_ noti: NSNotification) {
        setupLeftMenu()
    }
    
    @objc func clickedOnLeftMenuItem() {
        showSettingViewController()
    }
    
    func showSettingViewController() {
        let settingVC = UIStoryboard.init(name: "MainEx", bundle: nil).instantiateViewController(withIdentifier: "SettingsViewController")
        self.navigationController?.pushViewController(settingVC, animated: true)
    }
    
    @objc public func displayList(_ recentsDataSource: MXKRecentsDataSource) {
        
    }
    
    @objc public func dataSource(_ dataSource: MXKDataSource?, didCellChange changes: Any?) {
    }
    
    @objc public func cellViewClass(forCellData cellData: MXKCellData?) -> AnyClass {
        if let cellDataStoring = cellData as? MXKRecentCellDataStoring {
            if let roomSummary = cellDataStoring.roomSummary {
                if let room = roomSummary.room {
                    if let summary = room.summary {
                        if summary.membership != MXMembership.invite {
                            return MXKRecentTableViewCell.self
                        }
                    }
                }
            }
        }
        
        return MXKRecentTableViewCell.self
    }
}
