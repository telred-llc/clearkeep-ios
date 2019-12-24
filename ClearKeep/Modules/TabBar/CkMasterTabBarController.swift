//
//  CkMasterTabBarController.swift
//  Riot
//
//  Created by Sinbad Flyce on 11/27/18.
//  Copyright © 2018 matrix.org. All rights reserved.
//

import Foundation

extension MasterTabBarController {
    @objc func reflectingBadges() {}
}

final public class CkMasterTabBarController: MasterTabBarController {
    
    lazy var placeholderSearchBar = UISearchBar()
    
    let kHomeTabIndex           = 0
    let kHomeCallHistoryIndex   = 1
    let kHomeContactIndex       = 2
    
    var missedCount: UInt = 0
    let disposeBag = DisposeBag()
    
    var keyBackupAlert: UIAlertController?
    var keyBackupSetupCoordinatorBridgePresenter: KeyBackupSetupCoordinatorBridgePresenter?
    var keyBackupRecoverCoordinatorBridgePresenter: KeyBackupRecoverCoordinatorBridgePresenter?

    override public var preferredStatusBarStyle: UIStatusBarStyle {
        return themeService.attrs.statusBarStyle
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.setupNavigationBar()
        bindingTheme()

        // Observe server sync at room data source level too
        NotificationCenter.default.addObserver(self, selector: #selector(onSyncNotification), name: NSNotification.Name.mxSessionDidSync, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(appOnResume(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // hide navigation bar shadow
        navigationController?.navigationBar.shadowImage = UIImage()

        navigationController?.view.setNeedsLayout() // force update layout
        navigationController?.view.layoutIfNeeded() // to fix height of the navigation bar
        
        // Observe wrong backup version
        // Commenting out, now using auto-backup feature
//        NotificationCenter.default.addObserver(self, selector: #selector(keyBackupStateDidChange(_:)), name: NSNotification.Name.mxKeyBackupDidStateChange, object: nil)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // show navigation bar shadow
        navigationController?.navigationBar.shadowImage = UIImage()
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.mxKeyBackupDidStateChange, object: nil)
    }
    
    public override func showAuthenticationScreen() {

        if self.authViewController == nil && self.isCkAuthViewControllerPreparing == false {
            self.isCkAuthViewControllerPreparing = true
            AppDelegate.the()?.restoreInitialDisplay({
                self.performSegue(withIdentifier: "showAuth", sender: self)
            })
        }
    }
    
    public override func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        self.view.endEditing(true)
        self.performSegue(withIdentifier: "showUnifiedSearch", sender: nil)
        return false
    }

    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if segue.identifier == "showUnifiedSearch", let unifiedSearchViewController = segue.destination as? UnifiedSearchViewController {
            unifiedSearchViewController.searchBar.vc_searchTextField?.backgroundColor = themeService.attrs.searchBarBgColor
            unifiedSearchViewController.searchBar.vc_searchTextField?.textColor = themeService.attrs.secondTextColor
            unifiedSearchViewController.searchBar.setMagnifyingGlassColorTo(color: themeService.attrs.secondTextColor)
            unifiedSearchViewController.searchBar.setClearButtonColorTo(color: themeService.attrs.secondTextColor)
            unifiedSearchViewController.searchBar.vc_searchTextField?.theme.tintColor = themeService.attrStream { $0.placeholderTextFieldColor }
            unifiedSearchViewController.barTitleColor = themeService.attrs.navBarTintColor
            unifiedSearchViewController.defaultBarTintColor = themeService.attrs.navBarTintColor
            unifiedSearchViewController.navigationController?.view.backgroundColor = themeService.attrs.navBarBgColor
            
            unifiedSearchViewController.didSelectCreateNewRoom = { [weak self] in
                self?.homeViewController.showDirectChatVC()
            }
        }
    }
    
    public override func reflectingBadges() {
        // missed count
        let missedCountHomeScreen = self.homeViewController.missedDiscussionsCount
        // is not zero
        if missedCountHomeScreen > 0 {
            // update badge
            self.tabBar.items?[kHomeTabIndex].badgeValue = self.tabBarBadgeStringValue(missedCountHomeScreen)
        } else { 
            // zero badge
            self.tabBar.items?[kHomeTabIndex].badgeValue = nil
        } 
    }
    
    private func setupNavigationBar() {
        placeholderSearchBar.sizeToFit()
        placeholderSearchBar.placeholder = NSLocalizedString("search_default_placeholder", tableName: "Vector", bundle: Bundle.main, value: "", comment: "")
        placeholderSearchBar.setShowsCancelButton(false, animated: false)
        placeholderSearchBar.delegate = self

        let searchBarContainer = CKSearchBarContainerView(customSearchBar: placeholderSearchBar)
        searchBarContainer.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 44)
        navigationItem.titleView = searchBarContainer
    }

    private func bindingTheme() {
        self.tabBar.isTranslucent = false
        self.tabBar.theme.barTintColor = themeService.attrStream{ $0.primaryBgColor }

        // Binding navigation bar color
        themeService.attrsStream.subscribe(onNext: { [weak self] (theme) in
            self?.navigationController?.navigationBar.isTranslucent = false
            self?.navigationController?.navigationBar.shadowImage = UIImage()
            self?.navigationController?.navigationBar.tintColor = themeService.attrs.primaryTextColor
            self?.placeholderSearchBar.vc_searchTextField?.backgroundColor = theme.searchBarBgColor
            self?.changeNavigationBar(color: themeService.attrs.navBarBgColor)
            self?.setNeedsStatusBarAppearanceUpdate()
        }).disposed(by: disposeBag)
    }

    @objc func onSyncNotification() {
        CKRoomCacheManager.shared.syncAllRooms(mxSession: self.mxSessions?.first as? MXSession)
    }
}

extension CkMasterTabBarController {
    
    /**
     Show KeyBackup creating controller
     */
    private func presentKeyBackupSetup() {
        guard let mainSession = self.mxSessions.first as? MXSession else {
            return
        }
        self.keyBackupSetupCoordinatorBridgePresenter = KeyBackupSetupCoordinatorBridgePresenter(session: mainSession)
        self.keyBackupSetupCoordinatorBridgePresenter?.present(from: self, isStartedFromSignOut: false, animated: true)
        self.keyBackupSetupCoordinatorBridgePresenter?.delegate = self
    }
    
    /**
     Show trust KeyBackup exist controller
     */
    private func presentKeyBackupRecover(keyBackupVersion: MXKeyBackupVersion) {
        guard let mainSession = self.mxSessions.first as? MXSession else {
            return
        }
        AppDelegate.the()?.isFirstLogin = false

        self.keyBackupRecoverCoordinatorBridgePresenter = KeyBackupRecoverCoordinatorBridgePresenter(session: mainSession, keyBackupVersion: keyBackupVersion)
        self.keyBackupRecoverCoordinatorBridgePresenter?.present(from: self, animated: true)
        self.keyBackupRecoverCoordinatorBridgePresenter?.delegate = self
    }
}

extension CkMasterTabBarController: KeyBackupSetupCoordinatorBridgePresenterDelegate {
    
    func keyBackupSetupCoordinatorBridgePresenterDelegateDidCancel(_ keyBackupSetupCoordinatorBridgePresenter: KeyBackupSetupCoordinatorBridgePresenter) {
        if self.keyBackupSetupCoordinatorBridgePresenter != nil {
            self.keyBackupSetupCoordinatorBridgePresenter?.dismiss(animated: true)
            self.keyBackupSetupCoordinatorBridgePresenter = nil
        }
        
    }
    
    func keyBackupSetupCoordinatorBridgePresenterDelegateDidSetupRecoveryKey(_ keyBackupSetupCoordinatorBridgePresenter: KeyBackupSetupCoordinatorBridgePresenter) {
        if self.keyBackupSetupCoordinatorBridgePresenter != nil {
            self.keyBackupSetupCoordinatorBridgePresenter?.dismiss(animated: true)
            self.keyBackupSetupCoordinatorBridgePresenter = nil
        }
    }
}

extension CkMasterTabBarController: KeyBackupRecoverCoordinatorBridgePresenterDelegate {
    
    func keyBackupRecoverCoordinatorBridgePresenterDidCancel(_ keyBackupRecoverCoordinatorBridgePresenter: KeyBackupRecoverCoordinatorBridgePresenter) {
        if self.keyBackupRecoverCoordinatorBridgePresenter != nil {
            self.keyBackupRecoverCoordinatorBridgePresenter?.dismiss(animated: true)
            self.keyBackupRecoverCoordinatorBridgePresenter = nil
        }
    }
    
    func keyBackupRecoverCoordinatorBridgePresenterDidRecover(_ keyBackupRecoverCoordinatorBridgePresenter: KeyBackupRecoverCoordinatorBridgePresenter) {
        if self.keyBackupRecoverCoordinatorBridgePresenter != nil {
            self.keyBackupRecoverCoordinatorBridgePresenter?.dismiss(animated: true)
            self.keyBackupRecoverCoordinatorBridgePresenter = nil
        }
    }
}


extension CkMasterTabBarController {
    
    private func forceUpdateVersion() {
        
        // force remove topSpinner
        if topSpinner != nil {
            self.removeSpinner()
        }
        
        showSpinner()
        
        CKAppManager.shared.apiClient.getCurrentVersion(CKAppVersion.Request()).done { response in
            if response.version != AppInfo.currentVersion {
                let alertVC = UIAlertController(title: CKLocalization.string(byKey: "current_version_title"),
                                                message: CKLocalization.string(byKey: "current_version_message"), preferredStyle: .alert)
                
                alertVC.addAction(UIAlertAction(title: CKLocalization.string(byKey: "current_version_update").uppercased(), style: .cancel, handler: { (action) in
                    if UIApplication.shared.canOpenURL(AppInfo.AppStote.urlStote) {
                        UIApplication.shared.open(AppInfo.AppStote.urlStote, options: [:]) { _ in
                            self.removeSpinner()
                        }
                    } else {
                        UIApplication.shared.open(AppInfo.AppStote.urlHttp, options: [:]) { _ in
                            self.removeSpinner()
                        }
                    }
                }))
                
                alertVC.view.theme.tintColor = themeService.attrStream { $0.navBarTintColor }
                self.present(alertVC, animated: true) { }
                
            } else {
                self.removeSpinner()
            }
        }.catch { error in
            
            self.removeSpinner()
        }
    }
    
    
    @objc func appOnResume(_ notification: Notification) {
//        forceUpdateVersion()
    }
}
