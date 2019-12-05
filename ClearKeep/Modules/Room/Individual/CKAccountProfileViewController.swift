//
//  CKAccountProfileViewController.swift
//  Riot
//
//  Created by Hiếu Nguyễn on 1/23/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit
import PromiseKit

class CKAccountProfileViewController: MXKViewController {
    
    // MARK: - OUTLET
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - ENUM
    
    private enum Section: Int {
        case avatar  = 0
        case detail  = 1
        case signOut = 2
        
        static var count: Int { return 3 }
    }
    
    // MARK: - CLASS
    
    public class func instance() -> CKAccountProfileViewController? {
        let instance = CKAccountProfileViewController(nibName: self.nibName, bundle: nil)
        return instance
    }
    
    // MARK: - PROPERTY
    
    private weak var signOutButton: UIButton?
    
    private var request: MXHTTPOperation!
    private var myUser: MXMyUser?
    private let kCkRoomAdminLevel = 100
    
    public var mxRoomPowerLevels: MXRoomPowerLevels?
    
    var signOutAlertPresenter: SignOutAlertPresenter?
    var keyBackupSetupCoordinatorBridgePresenter: KeyBackupSetupCoordinatorBridgePresenter?

    // Observers
    private var removedAccountObserver: Any?
    private var accountUserInfoObserver: Any?
    private var pushInfoUpdateObserver: Any?

    private let disposeBag = DisposeBag()
    
    var imagePickedBlock: ((UIImage) -> Void)?

    /**
     When you want this controller always behavior a presenting controller, set true it
     */
    internal var isForcedPresenting = false
    
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
        accountUserInfoObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.mxkAccountUserInfoDidChange, object: nil, queue: OperationQueue.main, using: { noti in
            
            let account = MXKAccountManager.shared()?.accounts.first
            if let account = account, let accountUserId = noti.object as? String, account.mxCredentials.userId == accountUserId {
                self.stopActivityIndicator()
                self.refreshData()
            }
        })
        
        // Add observer to push settings
        pushInfoUpdateObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.mxkAccountPushKitActivityDidChange, object: nil, queue: OperationQueue.main, using: { notif in
            
            self.stopActivityIndicator()
            self.refreshData()
        })
        
        if self.isForcedPresenting {
            // Setup close button item
            let closeItemButton = UIBarButtonItem.init(
                image: UIImage(named: "ic_x_close"),
                style: .plain,
                target: self, action: #selector(clickedOnBackButton(_:)))
            closeItemButton.tintColor = themeService.attrs.navBarTintColor
            
            // set nv items
            self.navigationItem.leftBarButtonItem = closeItemButton
        }

        // init sign out alert
        self.signOutAlertPresenter = SignOutAlertPresenter()
        self.signOutAlertPresenter?.delegate = self
        
        self.bindingTheme()
    }
    
    @objc func clickedOnBackButton(_ sender: Any?) {
        self.dismiss(animated: true, completion: nil)
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
        self.tableView.register(CKAccountProfileInfoCell.nib, forCellReuseIdentifier: CKAccountProfileInfoCell.identifier)
        self.tableView.register(CKSignoutButtonTableViewCell.nib, forCellReuseIdentifier: CKSignoutButtonTableViewCell.identifier)
        self.tableView.register(CKUserProfileDetailCell.nib, forCellReuseIdentifier: CKUserProfileDetailCell.identifier)
        self.tableView.allowsSelection = false
        self.tableView.keyboardDismissMode = .onDrag
        
        
        // add setting barButtonItem
        let settingItem = UIBarButtonItem(image: #imageLiteral(resourceName: "setting_profile").withRenderingMode(.alwaysTemplate),
                                          style: .plain,
                                          target: self,
                                          action:  #selector(handleSettingButton(_:)))
        
        settingItem.theme.tintColor = themeService.attrStream{ $0.primaryTextColor }
        navigationItem.rightBarButtonItem = settingItem
        
        addCustomBackButton()
        
        let tapAction = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tapAction.cancelsTouchesInView = false
        UIApplication.shared.sendAction(#selector(UIApplication.resignFirstResponder), to: nil, from: nil, for: nil)
        view.addGestureRecognizer(tapAction)
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    @objc private func handleSettingButton(_ sender: UIBarButtonItem) {
        
        let settingVC = CKSettingsViewController.init(nibName: "CKSettingsViewController", bundle: Bundle.init(for: CKSettingsViewController.self))
        settingVC.importSession(self.mxSessions)
        self.navigationController?.pushViewController(settingVC, animated: true)
    }

    func bindingTheme() {
        // Binding navigation bar color
        themeService.attrsStream.subscribe(onNext: { [weak self] (theme) in
            self?.defaultBarTintColor = themeService.attrs.navBarBgColor
            self?.barTitleColor = themeService.attrs.navBarTintColor
            self?.tableView.reloadData()
        }).disposed(by: disposeBag)

        themeService.rx
            .bind({ $0.primaryBgColor }, to: view.rx.backgroundColor, tableView.rx.backgroundColor)
            .disposed(by: disposeBag)
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
            
            cell.isCanEditDisplayName = true
            cell.currentDisplayName = myUser?.displayname.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            
            if let myUser = self.myUser {
                
                //status
                switch myUser.presence {
                case MXPresenceOnline:
                    cell.settingStatus(online: true)
                default:
                    cell.settingStatus(online: false)
                }
                
                cell.setAvatarUri(
                    myUser.avatarUrl,
                    identifyText: myUser.userId,
                    session: self.mainSession,
                    cropped: false)
                if let powerLevels = mxRoomPowerLevels, powerLevels.powerLevelOfUser(withUserID: myUser.userId) == kCkRoomAdminLevel {
                    cell.isAdminPower = true
                } else {
                    cell.isAdminPower = false
                }
            } else {
                cell.settingStatus(online: false)
                cell.avaImage.image = nil
            }
            
            
            cell.editAvatar = {
                self.handlerEditAvatar()
            }
            
            cell.editDisplayName = { newDisplayName in
                
                self.showSpinner()
                
                let account = MXKAccountManager.shared().activeAccounts.first
                
                account?.setUserDisplayName(newDisplayName, success: {
                    
                    self.showAlert(CKLocalization.string(byKey: "profile_update_success")) {
                        self.reloadAvatarCell()
                        cell.isShowDoneButton = false
                    }
                }, failure: { (error) in
                    self.reloadAvatarCell()
                    self.showAlert(error?.localizedDescription ?? "Error")
                })
            }
            
            imagePickedBlock = { (image) in
                
                self.updateAvatar(image, cell: cell)
            }

            return cell
        }
        return CKAccountProfileAvatarCell()
    }
    
    private func updateAvatar(_ image: UIImage, cell: CKAccountProfileAvatarCell) {
        let account = MXKAccountManager.shared().activeAccounts.first
        guard let updatedPicture = MXKTools.forceImageOrientationUp(image) else { return }
        
        self.showSpinner()
        
        let uploader: MXMediaLoader? = MXMediaManager.prepareUploader(withMatrixSession: account?.mxSession, initialRange: 0.0, andRange: 1.0)
    
        uploader?.uploadData(UIImageJPEGRepresentation(updatedPicture, 0.5),
                             filename: nil,
                             mimeType: "image/jpeg",
                             success: { (url) in
                                
                                account?.setUserAvatarUrl(url, success: {
                                    self.showAlert(CKLocalization.string(byKey: "profile_update_success")) {
                                        self.reloadAvatarCell()
                                    }
                                }, failure: { (error) in
                                    self.reloadAvatarCell()
                                    self.showAlert(error?.localizedDescription ?? "Error")
                                })
                                
        }, failure: { (error) in
            self.reloadAvatarCell()
            self.showAlert(error?.localizedDescription ?? "Error")
        })
        
    }
    
    private func cellForInfoPersonal(atIndexPath indexPath: IndexPath) -> CKUserProfileDetailCell {
        
        if let cell = tableView.dequeueReusableCell(
            withIdentifier: CKUserProfileDetailCell.identifier,
            for: indexPath) as? CKUserProfileDetailCell {
            switch indexPath.row {
            case 0:
                cell.bindingData(icon: #imageLiteral(resourceName: "user_profile"), content: myUser?.userId, placeholder: "")
            case 1:
                cell.bindingData(icon: #imageLiteral(resourceName: "location_profile"), content: nil, placeholder: CKLocalization.string(byKey: "profile_location_placeholder"))
            case 2:
                cell.bindingData(icon: #imageLiteral(resourceName: "phone_profile"), content: nil, placeholder: CKLocalization.string(byKey: "profile_phone_placeholder"))
            default:
                break
            }
            return cell
        }
        
        return CKUserProfileDetailCell()
    }
    
    private func cellForSignOutButton(atIndexPath indexPath: IndexPath) -> CKSignoutButtonTableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: CKSignoutButtonTableViewCell.identifier, for: indexPath) as? CKSignoutButtonTableViewCell {

            cell.signOutHandler = { [weak self] in
                self?.signOut(button: cell.signOutButton)
            }
        }
        
        return CKSignoutButtonTableViewCell()
        
    }
    
    private func reloadAvatarCell() {
        self.removeSpinner()
        self.tableView.reloadSections([Section.avatar.rawValue], with: .automatic)
    }
    
    
    // -- show alert choose edit avatar: camera + photoLibrary
    private func handlerEditAvatar() {
        
        let optionAlert = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
        
        optionAlert.addAction(UIAlertAction.init(title: CKLocalization.string(byKey: "alert_take_photo"), style: .default, handler: { [weak self] (action) in
            
            if UIImagePickerController.isSourceTypeAvailable(.camera){
                let myPickerController = UIImagePickerController()
                myPickerController.sourceType = .camera
                myPickerController.delegate = self;
                self?.present(myPickerController, animated: true, completion: nil)
            }
        }))
        
        optionAlert.addAction(UIAlertAction.init(title: CKLocalization.string(byKey: "alert_choose_from_library"), style: .default, handler: { [weak self] (action) in
            let imagePickerController = UIImagePickerController()
            imagePickerController.sourceType = .photoLibrary
            imagePickerController.delegate = self
            self?.present(imagePickerController, animated: true, completion: nil)

        }))
        
        optionAlert.addAction(UIAlertAction.init(title: CKLocalization.string(byKey: "cancel"), style: .cancel, handler: { (action) in
        }))
        
        optionAlert.presentGlobally(animated: true, completion: nil)
    }
}

// MARK: Handler Sign out
extension CKAccountProfileViewController {
    
    private func signOut(button: UIButton) {
        //  Check sign out when use KeyBackup
        self.signOutButton = button
        if let keyBackup = self.mainSession.crypto.backup {
            self.signOutAlertPresenter?.present(for: keyBackup.state, areThereKeysToBackup: keyBackup.hasKeysToBackup, from: self, sourceView: button, animated: true)
            return
        }
        
        button.isEnabled = false
        self.showSpinner()
        AppDelegate.the().logout(withConfirmation: true) { [weak self] isLoggedOut in
            // Enable the button and stop activity indicator
            button.isEnabled = true
            self?.removeSpinner()

            if isLoggedOut {
                // Clear all cached rooms
                CKRoomCacheManager.shared.clearAllCachedData()
                CKKeyBackupRecoverManager.shared.destroy()
            }
        }
    }
}

// MARK: - UITableViewDelegate

extension CKAccountProfileViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let section = Section(rawValue: indexPath.section) else { return 0}
        switch section {
        case .avatar:
            return UITableViewAutomaticDimension
        case .signOut:
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
        case .detail: return 3
        case .signOut: return 1
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
        case .signOut:
            return cellForSignOutButton(atIndexPath: indexPath)
        }
    }
}

extension CKAccountProfileViewController: SignOutAlertPresenterDelegate {
    
    func signOutAlertPresenterDidTapSignOutAction(_ presenter: SignOutAlertPresenter) {
        // Prevent user to perform user interaction in settings when sign out
        // TODO: Prevent user interaction in all application (navigation controller and split view controller included)
        self.showSpinner()
        self.signOutButton?.isEnabled = false
        
        AppDelegate.the().logout(withConfirmation: false) { [weak self] isLoggedOut in
            // Enable the button and stop activity indicator
            self?.removeSpinner()
            self?.signOutButton?.isEnabled = true

            if isLoggedOut {
                CKRoomCacheManager.shared.clearAllCachedData()
                CKKeyBackupRecoverManager.shared.destroy()
            }
        }
    }
    
    func signOutAlertPresenterDidTapBackupAction(_ presenter: SignOutAlertPresenter) {
        self.showKeyBackupSetupFromSignOutFlow(showFromSignOutFlow: true)
    }
    
    private func showKeyBackupSetupFromSignOutFlow(showFromSignOutFlow: Bool) {
        self.keyBackupSetupCoordinatorBridgePresenter = KeyBackupSetupCoordinatorBridgePresenter(session: mainSession)
        self.keyBackupSetupCoordinatorBridgePresenter?.present(from: self, isStartedFromSignOut: showFromSignOutFlow, animated: true)
        self.keyBackupSetupCoordinatorBridgePresenter?.delegate = self
    }
}

extension CKAccountProfileViewController: KeyBackupSetupCoordinatorBridgePresenterDelegate {
    
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


// MARK: UIImagePickerControllerDelegate
extension CKAccountProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            return
        }
        
        self.dismiss(animated: true, completion: { [weak self] in
            self?.imagePickedBlock?(image)
        })
    }
}
