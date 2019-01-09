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
    
    lazy var directMessageVC = {
        Bundle.main.loadNibNamed("CKDirectMessagePageViewController", owner: nil, options: nil)?.first as! CKDirectMessagePageViewController
    }()
    lazy var roomVC = {
        Bundle.main.loadNibNamed("CKRoomPageViewController", owner: nil, options: nil)?.first as! CKRoomPageViewController
    }()
    
    var avatarTapGestureRecognizer: UITapGestureRecognizer?
    let pagingViewController = PagingViewController<PagingIndexItem>.init()
    var recentsDataSource: RecentsDataSource?
    
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
}

// MARK: - PagingViewControllerDataSource

extension CkHomeViewController: PagingViewControllerDataSource {
    func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, pagingItemForIndex index: Int) -> T where T : PagingItem, T : Comparable, T : Hashable {
        switch index {
        case 0:
            let peopleArray = self.recentsDataSource?.peopleCellDataArray
            return PagingIndexItem(index: index, title: "Direct Message(\(peopleArray?.count ?? 0))") as! T
        case 1:
            let roomsArray = self.recentsDataSource?.conversationCellDataArray
            return PagingIndexItem(index: index, title: "Room(\(roomsArray?.count ?? 0))") as! T
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

extension CkHomeViewController {
    @objc override func onMatrixSessionChange() {
        super.onMatrixSessionChange()
        
        let mxSessions = self.mxSessions as? [MXSession]
        mxSessions.flatMap({ return $0 })?.forEach({ (mxSession) in
            if MXKRoomDataSourceManager.sharedManager(forMatrixSession: mxSession)?.isServerSyncInProgress == true {
                // sync is in progress for at least one data source, keep running the loading wheel
                self.activityIndicator.startAnimating()
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
        // reload pager
        self.pagingViewController.reloadData()

        self.reloadDirectMessagePage()
        self.reloadRoomPage()
    }
    
    func dataSource(_ dataSource: MXKDataSource!, didAddMatrixSession mxSession: MXSession!) {
        self.addMatrixSession(mxSession)
    }
    
    func dataSource(_ dataSource: MXKDataSource!, didRemoveMatrixSession mxSession: MXSession!) {
        self.removeMatrixSession(mxSession)
    }
    
    private func reloadRoomPage() {
        if let roomsArray = self.recentsDataSource?.conversationCellDataArray as? [MXKRecentCellData] {
            roomVC.reloadData(rooms: roomsArray)
        } else {
            roomVC.reloadData(rooms: [])
        }
    }
    
    private func reloadDirectMessagePage() {
        if let peopleArray = self.recentsDataSource?.peopleCellDataArray as? [MXKRecentCellData] {
            directMessageVC.reloadData(rooms: peopleArray)
        } else {
            directMessageVC.reloadData(rooms: [])
        }
    }
}
