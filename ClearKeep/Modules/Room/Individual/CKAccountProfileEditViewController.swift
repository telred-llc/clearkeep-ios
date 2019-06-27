//
//  CKAccountProfileViewController.swift
//  Riot
//
//  Created by Hiếu Nguyễn on 1/23/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit
import PromiseKit

/**
 Account Profile creating data
 */
private struct AccountProfileSavingData {
    var userId: String?
    var displayName: String?
    var status: String?
    var career: String?
    var contact: String?
    
    static func == (lhs: inout AccountProfileSavingData, rhs: AccountProfileSavingData) -> Bool {
        return (lhs.displayName == rhs.displayName
            && lhs.status == rhs.status
            && lhs.career == rhs.career
            && lhs.contact == rhs.contact
            && lhs.userId == rhs.userId)
    }
    
    func isValidated() -> Bool {
        return (self.displayName ?? "").count > 0
    }
}

/**
 Controller class
 */
final class CKAccountProfileEditViewController: MXKViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
    // MARK: - OUTLET
    @IBOutlet weak var tableView: UITableView!
    
    
    //MARK: Internal Properties
    var imagePickedBlock: ((UIImage) -> Void)?
    
    // MARK: - ENUM
    
    private enum Section: Int {
        case avatarname  = 0
        case userId = 1
        
        static var count: Int { return 2}
    }
    
    // MARK: - CLASS
        
    // MARK: - PROPERTY
    
    /**
     MX Room
     */
    public var mxRoom: MXRoom!
    
    /**
     VAR saving data
     */
    private var savingData = AccountProfileSavingData.init()
    
    private var request: MXHTTPOperation!
    typealias blockSettingsViewController_onReadyToDestroy = () -> Void
    
    private var removedAccountObserver: Any?
    private var accountUserInfoObserver: Any?
    private var pushInfoUpdateObserver: Any?

    private var currentAlert: UIAlertController?
    private var newAvatarImage: UIImage?
    private var uploadedAvatarURL : String?
    private var isSavingInProgress: Bool?
    private var deviceView: MXKDeviceView?
    private var onReadyToDestroyHandler: blockSettingsViewController_onReadyToDestroy?

    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()        
        self.finalizeLoadView()
        self.bindingTheme()
        
        // Add observer to handle removed accounts
        removedAccountObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.mxkAccountManagerDidRemoveAccount, object: nil, queue: OperationQueue.main, using: { notif in

            if (MXKAccountManager.shared().accounts ?? []).count > 0 {
                // Refresh table to remove this account
                self.refreshSavingData()
            }

        })

        // Add observer to handle accounts update
        accountUserInfoObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.mxkAccountUserInfoDidChange, object: nil, queue: OperationQueue.main, using: { noti in
            
            let account = MXKAccountManager.shared()?.accounts.first
            if let account = account, let accountUserId = noti.object as? String, account.mxCredentials.userId == accountUserId {
                self.stopActivityIndicator()
                self.refreshSavingData()
            }
        })
        
        // Add observer to push settings
        pushInfoUpdateObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.mxkAccountPushKitActivityDidChange, object: nil, queue: OperationQueue.main, using: { notif in
            
            self.stopActivityIndicator()
            self.refreshSavingData()
        })
        
        self.refreshSavingData()
    }
    
    override func finalizeInit() {
        super.finalizeInit()
        enableBarTintColorStatusChange = false
        isSavingInProgress = false
    }
    
    deinit {
        if request != nil {
            request.cancel()
            request = nil
        }
    }
    
    override func destroy()  {
        if isSavingInProgress == false {
            onReadyToDestroyHandler = { [weak self] in
                self?.destroy()
            }
        } else {
            
            // Dispose all resources
            self.reset()
            super.destroy()
        }
    }
    
    func reset() {
        onReadyToDestroyHandler = nil

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

        if (deviceView != nil) {
            deviceView?.removeFromSuperview()
            deviceView = nil
        }
    }

    func bindingTheme() {
        // Binding navigation bar color
        themeService.attrsStream.subscribe(onNext: { [weak self] (theme) in
            self?.defaultBarTintColor = themeService.attrs.primaryBgColor
            self?.barTitleColor = themeService.attrs.primaryTextColor
        }).disposed(by: disposeBag)

        themeService.rx
            .bind({ $0.secondBgColor }, to: view.rx.backgroundColor, tableView.rx.backgroundColor)
            .disposed(by: disposeBag)
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
        self.refreshSavingData()
    }
    
    private func getMyUser() -> MXMyUser? {
        let session = AppDelegate.the()?.mxSessions.first as? MXSession
        if let myUser = session?.myUser {
            return myUser
        }
        return nil
    }
    
    private func refreshSavingData() {
        
        if let myUser = self.getMyUser() {
            let userId = myUser.userId
            let displayName = myUser.displayname
            let statusMsg = myUser.statusMsg
            
            savingData = AccountProfileSavingData.init(userId: userId, displayName: displayName, status: statusMsg, career: nil, contact: nil)
        } else {
            savingData = AccountProfileSavingData.init()
        }
        
        self.updateSaveButtonStatus()
        self.tableView.reloadData()
    }
    
    // MARK: - PRIVATE
    
    private func finalizeLoadView() {
        
        // title
        self.navigationItem.title = "Edit Profile"
        
        // register cells
        self.tableView.register(CKAccountEditProfileAvatarCell.nib, forCellReuseIdentifier: CKAccountEditProfileAvatarCell.identifier)
        self.tableView.register(CKEditProfileWithTextFieldTableViewCell.nib, forCellReuseIdentifier: CKEditProfileWithTextFieldTableViewCell.identifier)
        self.tableView.allowsSelection = false
        self.tableView.backgroundColor = UIColor.clear
        self.tableView.estimatedRowHeight = 97
        self.tableView.contentInset = UIEdgeInsetsMake(40, 0, 0, 0)
        
        // Setup cancel button item
        let cancelItemButton = UIBarButtonItem.init(
            title: "Cancel",
            style: .plain, target: self,
            action: #selector(clickedOnCancelButton(_:)))
        
        // Setup save button item
        let saveItemButton = UIBarButtonItem.init(
            title: "Save",
            style: .plain, target: self,
            action: #selector(clickedOnSaveButton(_:)))
        
        saveItemButton.isEnabled = false
        
        // assign back button
        self.navigationItem.leftBarButtonItem = cancelItemButton
        self.navigationItem.rightBarButtonItem = saveItemButton
    }
    
    
    func updateSaveButtonStatus() {
        if AppDelegate.the().mxSessions.count > 0 {
            let session = AppDelegate.the().mxSessions[0] as? MXSession
            let myUser: MXMyUser? = session?.myUser

            let saveButtonEnabled: Bool = nil != newAvatarImage || ((savingData.displayName ?? "").count > 0 && myUser?.displayname != savingData.displayName)
            navigationItem.rightBarButtonItem?.isEnabled = saveButtonEnabled
        }
    }

    private func saveData(completion: ((Bool) -> Void)? = nil)  {
        
        // sanity check
        if MXKAccountManager.shared().activeAccounts.count == 0 {
            completion?(true)
            return
        }
        
        
        firstly { () -> PromiseKit.Promise<Bool> in
            
            self.navigationItem.rightBarButtonItem?.isEnabled = false
            self.startActivityIndicator()
            self.isSavingInProgress = true
            
            return saveNewDisplayName()
            }.then { (success) -> PromiseKit.Promise<String?> in
                if success {
                    return self.uploadAvatar()
                } else {
                    throw PMKError.cancelled
                }
            }.then({ (uploadedAvatarUrl) -> PromiseKit.Promise<Void> in
                if let uploadedAvatarUrl = uploadedAvatarUrl {
                    self.uploadedAvatarURL = uploadedAvatarUrl
                    self.newAvatarImage = nil
                    return self.setUserAvatar(url: uploadedAvatarUrl)
                } else {
                    throw PMKError.cancelled
                }
            }).done {
                //
                completion?(true)
            }.ensure {
                
                // Backup is complete
                self.isSavingInProgress = false
                self.stopActivityIndicator()
                
                // Check whether destroy has been called durign saving
                if self.onReadyToDestroyHandler != nil {
                    self.onReadyToDestroyHandler!()
                    self.onReadyToDestroyHandler = nil
                } else {
                    self.tableView.reloadData()
                }
            }.catch { (error) in
                if !error.isCancelled {
                    self.handleErrorDuringProfileChangeSaving(error: error as NSError)
                }
                completion?(false)
        }
    }

    func saveNewDisplayName() -> PromiseKit.Promise<Bool> {
        return PromiseKit.Promise<Bool> { resolver in
            let account = MXKAccountManager.shared().activeAccounts.first
            let myUser = account?.mxSession.myUser
            
            if savingData.displayName != nil && myUser?.displayname != savingData.displayName {
                account?.setUserDisplayName(savingData.displayName,
                                            success: {
                                                print("[SettingsViewController] Failed to set displayName")
                                                resolver.fulfill(true)
                    }, failure: { (error) in
                        resolver.reject(error ?? NSError())
                })
            } else {
                resolver.fulfill(true)
            }
        }
    }
    
    func uploadAvatar() -> PromiseKit.Promise<String?> {
        return PromiseKit.Promise<String?> { resolver in
            
            if let uploadedAvatarURL = self.uploadedAvatarURL {
                resolver.fulfill(uploadedAvatarURL)
                return
            }
            
            let account = MXKAccountManager.shared().activeAccounts.first
            if let newAvatarImage = newAvatarImage,
                let updatedPicture = MXKTools.forceImageOrientationUp(newAvatarImage) {
                // Upload picture
                let uploader: MXMediaLoader? = MXMediaManager.prepareUploader(withMatrixSession: account?.mxSession, initialRange: 0, andRange: 1.0)
                
                uploader?.uploadData(UIImageJPEGRepresentation(updatedPicture, 0.5), filename: nil, mimeType: "image/jpeg", success: { (url) in
                    resolver.fulfill(url)
                }, failure: { (error) in
                    print("Failed to upload image")
                    resolver.reject(error ?? NSError())
                })
                return
            } else {
                resolver.fulfill(nil)
            }
        }
    }
    
    func setUserAvatar(url: String) -> PromiseKit.Promise<Void> {
        return PromiseKit.Promise<Void> { resolver in
            let account = MXKAccountManager.shared().activeAccounts.first
            account?.setUserAvatarUrl(url, success: {
                resolver.fulfill(())
            }, failure: { (error) in
                print("Failed to set avatar url")
                resolver.reject(error ?? NSError())
            })
        }
    }
    
    func handleErrorDuringProfileChangeSaving(error: NSError) {
        // Sanity check: retrieve the current root view controller
        let rootViewController: UIViewController? = AppDelegate.the().window.rootViewController
        if rootViewController != nil {
            // Alert user
            var title = ((error as NSError?)!.userInfo)[NSLocalizedFailureReasonErrorKey] as? String
            if title == nil {
                title = Bundle.mxk_localizedString(forKey: "settings_fail_to_update_profile")
            }
            let msg = ((error as NSError?)!.userInfo)[NSLocalizedDescriptionKey] as? String
            
            currentAlert?.dismiss(animated: false)
            
            currentAlert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
            
            currentAlert?.addAction(UIAlertAction(title: Bundle.mxk_localizedString(forKey: "abort"), style: .default, handler: { (action) in
                
                self.currentAlert = nil
                
                // Reset the updated displayname
                self.savingData.displayName = nil
                
                // Discard picture change
                self.uploadedAvatarURL = nil
                self.newAvatarImage = nil
                
                // Loop to end saving
                self.saveData()
            }))
            
            currentAlert?.addAction(UIAlertAction(title: Bundle.mxk_localizedString(forKey: "retry"), style: .default, handler: { (action) in
                self.currentAlert = nil
                
            }))
            currentAlert?.mxk_setAccessibilityIdentifier("Failed Alert")
            rootViewController?.present(currentAlert!, animated: true, completion: nil)
        }
    }
    
    private func cellForAvatarPersonal(atIndexPath indexPath: IndexPath) -> CKAccountEditProfileAvatarCell {
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: CKAccountEditProfileAvatarCell.identifier, for: indexPath) as? CKAccountEditProfileAvatarCell {
            
            // Take Snap shoot
            cell.cameraHandler = {
                cell.nameTextField.resignFirstResponder()
                
                if UIImagePickerController.isSourceTypeAvailable(.camera){
                    let myPickerController = UIImagePickerController()
                    myPickerController.sourceType = .camera
                    myPickerController.delegate = self;
                    self.present(myPickerController, animated: true, completion: nil)
                }
            }
            
            cell.nameTextField.text = savingData.displayName

            // Display Avatar
            if let newAvatarImage = newAvatarImage {
                cell.avaImage.image = newAvatarImage
            } else if let myUser = self.getMyUser() {
                cell.setAvatarUri(
                    myUser.avatarUrl,
                    identifyText: myUser.userId,
                    session: self.mainSession)
            }
            
            cell.tapHandler = {
                
                cell.nameTextField.resignFirstResponder()
                
                let imagePickerController = UIImagePickerController()
                
                // Only allow photos to be picked, not taken.
                imagePickerController.sourceType = .photoLibrary
                
                // Make sure ViewController is notified when the user picks an image.
                imagePickerController.delegate = self
                self.present(imagePickerController, animated: true, completion: nil)
            }
            
            self.imagePickedBlock = { (image) in
                DispatchQueue.main.async {
                    cell.avaImage.image = image
                    self.newAvatarImage = cell.avaImage.image
                    self.updateSaveButtonStatus()
                }
            }
            
            // Text value
            cell.edittingChangedHandler = { text in
                if let text = text {
                    self.savingData.displayName = text
                    self.updateSaveButtonStatus()
                }
            }

            cell.theme.backgroundColor = themeService.attrStream{ $0.secondBgColor }
            cell.displayNameTitleLabel.theme.textColor = themeService.attrStream{ $0.secondTextColor }
            cell.nameTextField.theme.textColor = themeService.attrStream{ $0.primaryTextColor }
            cell.textInputContainerView.theme.backgroundColor = themeService.attrStream{ $0.primaryBgColor }

            return cell
        }
        return CKAccountEditProfileAvatarCell()
    }
    
    private func cellFor(atIndexPath indexPath: IndexPath) -> CKEditProfileWithTextFieldTableViewCell {
        
        // dequeue account display name cell
        if let cell = tableView.dequeueReusableCell(
            withIdentifier: CKEditProfileWithTextFieldTableViewCell.identifier,
            for: indexPath) as? CKEditProfileWithTextFieldTableViewCell {
            
            // default
            cell.titleLabel.text = nil
            cell.inputTextField.placeholder = nil
            
            if let section = Section(rawValue: indexPath.section) {
                switch section {
                case .userId:
                    cell.titleLabel.text = "User ID"
                    cell.inputTextField.isEnabled = false
                    cell.inputTextField.text = savingData.userId
                default:
                    break
                }
            }

            cell.theme.backgroundColor = themeService.attrStream{ $0.secondBgColor }
            cell.titleLabel.theme.textColor = themeService.attrStream{ $0.secondTextColor }
            cell.inputTextField.theme.textColor = themeService.attrStream{ $0.primaryTextColor }
            cell.inputTextFiedContainerView.theme.backgroundColor = themeService.attrStream{ $0.primaryBgColor }

            return cell
        }
        return CKEditProfileWithTextFieldTableViewCell()
    }

    //MARK: UIImagePickerControllerDelegate
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.imagePickedBlock?(image)
        }else{
            print("Something wrong")
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - ACTION
    
    @objc func clickedOnCancelButton(_ sender: Any?) {
        if self.navigationController != nil {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func clickedOnSaveButton(_ sender: Any?) {
        self.view.endEditing(true)
        self.saveData { (success) in
            if success {
                self.clickedOnCancelButton(sender)
            }
        }
    }
}
// MARK: - UITableViewDelegate

extension CKAccountProfileEditViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let section = Section(rawValue: indexPath.section) else { return 0}
        switch section {
        case .avatarname:
            return 100
        default:
            return UITableViewAutomaticDimension
        }
    }
}

// MARK: - UITableViewDataSource

extension CKAccountProfileEditViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard let section = Section(rawValue: section) else { return 0 }
        
        // number rows in case
        switch section {
        default:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let section = Section(rawValue: indexPath.section) else { return CKAccountEditProfileBaseCell() }
        
        switch section {
        case .avatarname:
            
            // account profile avatar name cell
            return cellForAvatarPersonal(atIndexPath: indexPath)
        default:
            return cellFor(atIndexPath: indexPath)
        }
    }
}



