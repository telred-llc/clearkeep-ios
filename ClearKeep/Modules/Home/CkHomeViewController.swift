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

final class CkHomeViewController: MXKViewController {
    
    // MARK: Properties
    
    var avatarTapGestureRecognizer: UITapGestureRecognizer?
    let directMessageVC = CKDirectMessagePageViewController.init(nibName: "CKDirectMessagePageViewController", bundle: nil)
    let roomVC = CKRoomPageViewController.init(nibName: "CKRoomPageViewController", bundle: nil)
    let pagingViewController = PagingViewController<PagingIndexItem>.init()

    // MARK: LifeCycle
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPageViewController()
        
        // Listen to the direct rooms list
        NotificationCenter.default.addObserver(self, selector: #selector(didDirectRoomsChange(_:)), name: NSNotification.Name.mxSessionDirectRoomsDidChange, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func setupPageViewController() {
        pagingViewController.dataSource = self
        
        // setup UI
        pagingViewController.indicatorOptions    = PagingIndicatorOptions.visible(height: 2, zIndex: Int.max, spacing: UIEdgeInsets.zero, insets: UIEdgeInsets.zero)
        pagingViewController.indicatorColor      = CKColor.Misc.primaryGreenColor
        pagingViewController.menuBackgroundColor = CKColor.Background.navigationBar
        pagingViewController.textColor           = CKColor.Text.lightGray
        pagingViewController.selectedTextColor   = CKColor.Misc.primaryGreenColor
        
        // Make sure you add the PagingViewController as a child view controller
        addChildViewController(pagingViewController)
        view.addSubview(pagingViewController.view)
        
        // constrain pagingViewController.view to the edges of the view.
        pagingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.safeAreaLayoutGuide.leftAnchor.constraint(equalTo: pagingViewController.view.leftAnchor).isActive = true
        view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: pagingViewController.view.topAnchor).isActive = true
        view.safeAreaLayoutGuide.rightAnchor.constraint(equalTo: pagingViewController.view.rightAnchor).isActive = true
        view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: pagingViewController.view.bottomAnchor).isActive = true

        pagingViewController.didMove(toParentViewController: self)
    }
    
    func setupNavigationBar() {
        guard let masterTabbar = AppDelegate.the()?.masterTabBarController else { return }
        // setup title
        masterTabbar.navigationItem.title = nil
        
        // setup left menu
        setupLeftMenu(navigationItem: masterTabbar.navigationItem)
        
        // setup right menu
        setupRightMenu(navigationItem: masterTabbar.navigationItem)
        
        // hide navigation bar shadow
        masterTabbar.navigationController?.navigationBar.shadowImage = UIImage()        
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
            
            navigationItem.leftBarButtonItem = UIBarButtonItem.init(customView: leftMenuView)
        } else {
            navigationItem.leftBarButtonItem = nil
        }
    }
    
    func setupRightMenu(navigationItem: UINavigationItem) {
        let newChatItem = UIBarButtonItem.init(image: UIImage.init(named: "ic_new_chat"), style: .plain, target: self, action: #selector(clickedOnRightMenuItem))
        navigationItem.rightBarButtonItem = newChatItem
    }
    
    @objc func didDirectRoomsChange(_ noti: NSNotification) {
        guard let masterTabbar = AppDelegate.the()?.masterTabBarController else { return }
        setupLeftMenu(navigationItem: masterTabbar.navigationItem)
    }
    
    @objc func clickedOnLeftMenuItem() {
        showSettingViewController()
    }
    
    @objc func clickedOnRightMenuItem() {
        print("\nclickedOnRightMenuItem")
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

// MARK: - PagingViewControllerDataSource

extension CkHomeViewController: PagingViewControllerDataSource {
    func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, pagingItemForIndex index: Int) -> T where T : PagingItem, T : Comparable, T : Hashable {
        switch index {
        case 0:
            return PagingIndexItem(index: index, title: "Direct Message(1)") as! T
        case 1:
            return PagingIndexItem(index: index, title: "Room(2)") as! T
        default:
            return PagingIndexItem(index: index, title: "") as! T
        }
    }
    
    func numberOfViewControllers<T>(in pagingViewController: PagingViewController<T>) -> Int {
        return 2
    }
    
    func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, viewControllerForIndex index: Int) -> UIViewController {
        switch index {
        case 0:
            return directMessageVC
        case 1:
            return roomVC
        default:
            return UIViewController()
        }
    }
}
