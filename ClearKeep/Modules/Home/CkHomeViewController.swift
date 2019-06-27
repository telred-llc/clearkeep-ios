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
    
    lazy var directMessageVC: CKDirectMessagePageViewController = {
        let vc = Bundle.main.loadNibNamed(CKDirectMessagePageViewController.nibName, owner: nil, options: nil)?.first as! CKDirectMessagePageViewController
        vc.delegate = self
        vc.importSession(self.mxSessions)
        return vc
    }()

    lazy var roomVC: CKRoomPageViewController = {
        let vc = Bundle.main.loadNibNamed(CKRoomPageViewController.nibName, owner: nil, options: nil)?.first as! CKRoomPageViewController
        vc.importSession(self.mxSessions)
        vc.delegate = self
        return vc
    }()
    
    var avatarTapGestureRecognizer: UITapGestureRecognizer?
    let pagingViewController = PagingViewController<CKPagingIndexItem>.init()
    var recentsDataSource: RecentsDataSource?
    var missedDiscussionsCount: Int = 0
    let disposeBag = DisposeBag()
    
    // MARK: LifeCycle
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPageViewController()

        // Listen to the user info did changed
        NotificationCenter.default.addObserver(self, selector: #selector(userInfoDidChanged(_:)), name: NSNotification.Name.mxkAccountUserInfoDidChange, object: nil)

        bindingTheme()
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

    func bindingTheme() {
        // Binding navigation bar color
        themeService.attrsStream.subscribe(onNext: { [weak self] (theme) in
            self?.defaultBarTintColor = themeService.attrs.primaryBgColor
            self?.barTitleColor = themeService.attrs.primaryTextColor
        }).disposed(by: disposeBag)

        pagingViewController.collectionView.theme.backgroundColor = themeService.attrStream{$0.primaryBgColor}
    }

    func setupPageViewController() {
        pagingViewController.dataSource = self
        pagingViewController.indicatorClass = PagingIndicatorView.self
        pagingViewController.menuItemSource = PagingMenuItemSource.nib(nib: UINib.init(nibName: "CKHomePagingWithBubbleCell", bundle: Bundle.init(for: CKHomePagingWithBubbleCell.self)))

        // setup UI
        pagingViewController.indicatorOptions    = PagingIndicatorOptions.visible(height: 0.75, zIndex: Int.max, spacing: UIEdgeInsets.zero, insets: UIEdgeInsets.zero)
        pagingViewController.indicatorColor      = CKColor.Misc.primaryGreenColor
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

// MARK: - PagingViewControllerDataSource

extension CkHomeViewController: PagingViewControllerDataSource {
    func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, pagingItemForIndex index: Int) -> T where T : PagingItem, T : Comparable, T : Hashable {
        
        var title: String = ""
        var bubbleTitle: String? = nil
        
        switch index {
        case 0:
            title = "\(String.ck_LocalizedString(key: "Direct Message"))"
            bubbleTitle = directMessageVC.missedItemCount > 0 ? "\(directMessageVC.missedItemCount)" : nil
        case 1:
            title = "\(String.ck_LocalizedString(key: "Room"))"
            bubbleTitle = roomVC.missedItemCount > 0 ? "\(roomVC.missedItemCount)" : nil
        default:
            break
        }
        
        return CKPagingIndexItem.init(index: index, title: title, bubbleTitle: bubbleTitle) as! T
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
        
        // reload pager
        self.pagingViewController.reloadData()
        
        // reflect tabbar
        self.missedDiscussionsCount = directMessageVC.missedItemCount + roomVC.missedItemCount
        AppDelegate.the()?.masterTabBarController.reflectingBadges()
    }
    
    func dataSource(_ dataSource: MXKDataSource!, didAddMatrixSession mxSession: MXSession!) {
        self.addMatrixSession(mxSession)
    }
    
    func dataSource(_ dataSource: MXKDataSource!, didRemoveMatrixSession mxSession: MXSession!) {
        self.removeMatrixSession(mxSession)
    }
    
//    private func reloadRoomPage() {
//        if var roomsArray = self.recentsDataSource?.conversationCellDataArray as? [MXKRecentCellData] {
//            if let invitesArray = self.recentsDataSource?.invitesCellDataArray as? [MXKRecentCellData] {
//                for invite in invitesArray.reversed() {
//                    if invite.roomSummary.isDirect == false {
//                        roomsArray.insert(invite, at: 0)
//                    }
//                }
//            }
//            roomVC.reloadData(rooms: roomsArray)
//        } else {
//            roomVC.reloadData(rooms: [])
//        }
//    }
//
//    private func reloadDirectMessagePage() {
//        if var peopleArray = self.recentsDataSource?.peopleCellDataArray as? [MXKRecentCellData] {
//
//            if let invitesArray = self.recentsDataSource?.invitesCellDataArray as? [MXKRecentCellData] {
//                for invite in invitesArray.reversed() {
//                    if invite.roomSummary.isDirect == true {
//                        peopleArray.insert(invite, at: 0)
//                    }
//                }
//            }
//
//            directMessageVC.reloadData(rooms: peopleArray)
//        } else {
//            directMessageVC.reloadData(rooms: [])
//        }
//    }
    
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
        
        roomVC.reloadData(rooms: rooms)
        directMessageVC.reloadData(rooms: rooms)
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
    func recentListViewDidTapStartChat(_ aClass: AnyClass) {
        if aClass == CKDirectMessagePageViewController.self {
            self.showDirectChatVC()
        } else if aClass == CKRoomPageViewController.self {
            self.showRoomChatVC()
        }
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
