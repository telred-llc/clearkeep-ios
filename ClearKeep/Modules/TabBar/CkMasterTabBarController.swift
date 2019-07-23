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
    
    let kHomeTabIndex       = 0
    let kHomeFavouriteIndex = 1
    let kHomeContactIndex   = 2
    
    var missedCount: UInt = 0
    let disposeBag = DisposeBag()
    
    var keyBackupAlert: UIAlertController?
    var keyBackupSetupCoordinatorBridgePresenter: KeyBackupSetupCoordinatorBridgePresenter?
    var keyBackupRecoverCoordinatorBridgePresenter: KeyBackupRecoverCoordinatorBridgePresenter?

    override public var preferredStatusBarStyle: UIStatusBarStyle {
        return themeService.attrs.statusBarStyle
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.setupNavigationBar()
        bindingTheme()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // hide navigation bar shadow
        navigationController?.navigationBar.shadowImage = UIImage()

        navigationController?.view.setNeedsLayout() // force update layout
        navigationController?.view.layoutIfNeeded() // to fix height of the navigation bar
        
        // Observe wrong backup version
        NotificationCenter.default.addObserver(self, selector: #selector(keyBackupStateDidChange(_:)), name: NSNotification.Name.mxKeyBackupDidStateChange, object: nil)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // show navigation bar shadow
        navigationController?.navigationBar.shadowImage = nil
        
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
        
        if let searchVC = UIStoryboard.init(name: "MainEx", bundle: nil).instantiateViewController(withIdentifier: "UnifiedSearchViewController") as? UnifiedSearchViewController {
            searchVC.searchBar.setTextFieldColor(color: themeService.attrs.secondBgColor)
            searchVC.barTitleColor = themeService.attrs.primaryTextColor
            searchVC.defaultBarTintColor = themeService.attrs.primaryBgColor
            searchVC.importSession(self.mxSessions)
            self.navigationController?.pushViewController(searchVC, animated: false)
        }
        return false
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

        let missedCountFavouritesScreen = self.favouritesViewController.missedDiscussionsCount
        if missedCountFavouritesScreen > 0 {
            self.tabBar.items?[kHomeFavouriteIndex].badgeValue = self.tabBarBadgeStringValue(missedCountFavouritesScreen)
        } else {
            self.tabBar.items?[kHomeFavouriteIndex].badgeValue = nil
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

        themeService.attrsStream.subscribe(onNext: { [weak self] (theme) in
            self?.navigationController?.navigationBar.isTranslucent = false
            self?.navigationController?.navigationBar.setBackgroundImage(UIImage.init(color: theme.primaryBgColor), for: .default)

            self?.placeholderSearchBar.setTextFieldColor(color: theme.searchBarBgColor)
            self?.setNeedsStatusBarAppearanceUpdate()
        }).disposed(by: disposeBag)
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
        self.keyBackupRecoverCoordinatorBridgePresenter = KeyBackupRecoverCoordinatorBridgePresenter(session: mainSession, keyBackupVersion: keyBackupVersion)
        self.keyBackupRecoverCoordinatorBridgePresenter?.present(from: self, animated: true)
        self.keyBackupRecoverCoordinatorBridgePresenter?.delegate = self
    }
    
    @objc private func keyBackupStateDidChange(_ notification: Notification?) {
        if !AppDelegate.the().isFirstLogin {
            return
        }
        guard let keyBackup = notification?.object as? MXKeyBackup else {
            return
        }
        if self.currentAlert != nil {
            if keyBackup.state == MXKeyBackupStateNotTrusted || keyBackup.state == MXKeyBackupStateDisabled {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1, execute: {
                    self.keyBackupStateDidChange(notification)
                })
            }
            return
        }
        
        if keyBackup.state == MXKeyBackupStateNotTrusted, let keyBackupVersion = keyBackup.keyBackupVersion {
            if self.keyBackupAlert != nil {
                self.keyBackupAlert?.dismiss(animated: false)
            }
            self.keyBackupAlert = UIAlertController(title: CKLocalization.string(byKey: "key_backup_alert_title_status_not_trusted"), message: CKLocalization.string(byKey: "key_backup_alert_message_status_not_trusted"), preferredStyle: .alert)
            self.keyBackupAlert?.addAction(UIAlertAction(title: Bundle.mxk_localizedString(forKey: "ok"), style: .default, handler: { action in
                self.keyBackupAlert = nil
                self.presentKeyBackupRecover(keyBackupVersion: keyBackupVersion)
            }))
            self.keyBackupAlert?.addAction(UIAlertAction(title: CKLocalization.string(byKey: "cancel"), style: .cancel, handler: { action in
                self.keyBackupAlert = nil
            }))
            
            if let keyBackupAlert = self.keyBackupAlert {
                self.present(keyBackupAlert, animated: true)
            }
        } else if keyBackup.state == MXKeyBackupStateDisabled {
            if self.keyBackupAlert != nil {
                self.keyBackupAlert?.dismiss(animated: false)
            }
            self.keyBackupAlert = UIAlertController(title: CKLocalization.string(byKey: "key_backup_alert_title_status_disabled"), message: CKLocalization.string(byKey: "key_backup_alert_message_status_disabled"), preferredStyle: .alert)
            self.keyBackupAlert?.addAction(UIAlertAction(title: Bundle.mxk_localizedString(forKey: "ok"), style: .default, handler: { action in
                self.keyBackupAlert = nil
                self.presentKeyBackupSetup()
            }))
            self.keyBackupAlert?.addAction(UIAlertAction(title: CKLocalization.string(byKey: "cancel"), style: .cancel, handler: { action in
                self.keyBackupAlert = nil
                
            }))
            
            if let keyBackupAlert = self.keyBackupAlert {
                self.present(keyBackupAlert, animated: true)
            }
        }
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
