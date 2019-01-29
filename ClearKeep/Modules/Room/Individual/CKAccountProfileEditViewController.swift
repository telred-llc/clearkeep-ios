//
//  CKAccountProfileViewController.swift
//  Riot
//
//  Created by Hiếu Nguyễn on 1/23/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

/**
 Account Profile creating data
 */
private struct AccountProfileSavingData {
    var fullname: String
    var newDisplayName: String?
    var career: String
    var contact: String
    static func == (lhs: inout AccountProfileSavingData, rhs: AccountProfileSavingData) -> Bool {
        return (lhs.fullname == rhs.fullname
            && lhs.newDisplayName == rhs.newDisplayName
            && lhs.career == rhs.career
            && lhs.contact == rhs.contact)
    }
    
    func isValidated() -> Bool {
        return self.newDisplayName!.count > 0
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
        case displayname  = 1
        case career  = 2
        case contact = 3
        
        static var count: Int { return 4}
    }
    
    // MARK: - CLASS
    
    class func instance() -> CKAccountProfileEditViewController {
        let instance = CKAccountProfileEditViewController(nibName: self.nibName, bundle: nil)
        return instance
    }
    
    class func instanceForNavigationController(completion: ((_ instance: CKAccountProfileEditViewController) -> Void)?) -> UINavigationController {
        let vc = self.instance()
        completion?(vc)
        return UINavigationController.init(rootViewController: vc)
    }
    
    // MARK: - PROPERTY
    
    /**
     MX Room
     */
    public var mxRoom: MXRoom!
    
    /**
     VAR saving data
     */
    private var savingData = AccountProfileSavingData(fullname: "", newDisplayName: "", career: "", contact: "")
    
    private var request: MXHTTPOperation!
    typealias blockSettingsViewController_onReadyToDestroy = () -> Void
    
    public var mxRoomMember: MXRoomMember!
//    private var newDisplayName: String?
    private var currentAlert: UIAlertController?
    private var newAvatarImage: UIImage?
    private var uploadedAvatarURL : String?
    private var isSavingInProgress: Bool?
    private var deviceView: MXKDeviceView?
    private var onReadyToDestroyHandler: blockSettingsViewController_onReadyToDestroy?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.finalizeLoadView()
    }
    
    override func finalizeInit() {
        super.finalizeInit()
        enableBarTintColorStatusChange = false
        self.rageShakeManager = RageShakeManager.sharedManager() as? MXKResponderRageShaking
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
        
        if (deviceView != nil) {
            deviceView?.removeFromSuperview()
            deviceView = nil
        }
    }
    
    // MARK: - PRIVATE
    
    private func finalizeLoadView() {
        
        // title
        self.navigationItem.title = "Edit Profile"
        
        // register cells
        self.tableView.register(CKAccountEditProfileAvatarCell.nib, forCellReuseIdentifier: CKAccountEditProfileAvatarCell.identifier)
        self.tableView.register(CKAccountEditProfileNameCell.nib, forCellReuseIdentifier: CKAccountEditProfileNameCell.identifier)
        self.tableView.register(CKAccountEditProfileCareerCell.nib, forCellReuseIdentifier: CKAccountEditProfileCareerCell.identifier)
        self.tableView.register(CKAccountEditProfileContactCell.nib, forCellReuseIdentifier: CKAccountEditProfileContactCell.identifier)
        self.tableView.allowsSelection = false
        
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

            var saveButtonEnabled: Bool = nil != newAvatarImage

            if !saveButtonEnabled {
                if (savingData.newDisplayName != nil) {
                    saveButtonEnabled = !(myUser?.displayname == savingData.newDisplayName)
                }
            }
            navigationItem.rightBarButtonItem?.isEnabled = saveButtonEnabled
        }
    }

    
    
    private func saveData(_ sender: Any?)  {
        if MXKAccountManager.shared().activeAccounts.count == 0 {
            return
        }
    
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        self.startActivityIndicator()
        isSavingInProgress = true
        
        let account = MXKAccountManager.shared().activeAccounts.first
        let myUser = account?.mxSession.myUser
        
        if (savingData.newDisplayName != nil) && !(myUser?.displayname == savingData.newDisplayName) {
            account?.setUserDisplayName(savingData.newDisplayName,
                                        success: { [weak self] in
                                            self?.savingData.newDisplayName = nil
                                            self?.tableView.reloadData()
                }, failure: { (error) in
                    print("Failed to set displayName")
                    self.handleErrorDuringProfileChangeSaving(error: error! as NSError)
            })
            return
        }
        
        if newAvatarImage != nil {
            let updatedPicture: UIImage? = MXKTools.forceImageOrientationUp(newAvatarImage)
            // Upload picture
            let uploader: MXMediaLoader? = MXMediaManager.prepareUploader(withMatrixSession: account?.mxSession, initialRange: 0, andRange: 1.0)

            uploader?.uploadData(UIImageJPEGRepresentation(updatedPicture!, 0.5), filename: nil, mimeType: "image/jpeg", success: { (url) in
                self.uploadedAvatarURL = url
                self.newAvatarImage = nil
            }, failure: { (error) in
                print("Failed to upload image")
                self.handleErrorDuringProfileChangeSaving(error: error! as NSError)
            })
            return
        } else if uploadedAvatarURL != nil {
            account?.setUserAvatarUrl(uploadedAvatarURL, success: { [weak self] in
                self?.uploadedAvatarURL = nil
                self?.saveData(nil)
                }, failure: { (error) in
                    print("Failed to set avatar url")
                    self.handleErrorDuringProfileChangeSaving(error: error! as NSError)
            })
            return
        }
        
        // Backup is complete
        isSavingInProgress = false
        self.stopActivityIndicator()

        // Check whether destroy has been called durign saving
        if onReadyToDestroyHandler != nil {
            onReadyToDestroyHandler!()
            onReadyToDestroyHandler = nil
        } else {
            tableView.reloadData()
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
                self.savingData.newDisplayName = ""
                
                // Discard picture change
                self.uploadedAvatarURL = nil
                self.newAvatarImage = nil
                
                // Loop to end saving
                self.saveData(nil)
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
            
            cell.nameTextField.text = mxRoomMember.displayname

            // Display Avatar
            if let avtURL = self.mainSession.matrixRestClient.url(ofContent: mxRoomMember.avatarUrl) {
                cell.setAvatarImageUrl(urlString: avtURL, previewImage: nil)
            } else {
                newAvatarImage = AvatarGenerator.generateAvatar(forText: mxRoomMember.displayname)
                cell.avaImage.image = newAvatarImage
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
                }
            }
            
            // Text value
            cell.edittingChangedHandler = { text in
                if let text = text {
                    self.savingData.newDisplayName = text
                    self.updateSaveButtonStatus()
                    self.updateControls()
                }
            }
            return cell
        }
        return CKAccountEditProfileAvatarCell()
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
    
    
    private func cellForDisplayName(atIndexPath indexPath: IndexPath) -> CKAccountEditProfileNameCell {
        
        // dequeue account display name cell
        if let cell = tableView.dequeueReusableCell(
            withIdentifier: CKAccountEditProfileNameCell.identifier,
            for: indexPath) as? CKAccountEditProfileNameCell {
            
                // display name
            cell.nameTextField.text = mxRoomMember.displayname
                
            // text value
            cell.edittingChangedHandler = { text in
                if let text = text {
                    self.savingData.newDisplayName = text
                    self.updateControls()
                }
            }
            
            return cell
        }
        return CKAccountEditProfileNameCell()
    }
    
    
    private func cellForCareer(atIndexPath indexPath: IndexPath) -> CKAccountEditProfileCareerCell {
        
        // dequeue account career cell
        if let cell = tableView.dequeueReusableCell(
            withIdentifier: CKAccountEditProfileCareerCell.identifier,
            for: indexPath) as? CKAccountEditProfileCareerCell {
            cell.careerTextField.text = savingData.career
            
            // text value
            cell.edittingChangedHandler = { text in
                if let text = text {
                    self.savingData.career = text
                    self.updateControls()
                }
            }
            return cell
        }
        
        return CKAccountEditProfileCareerCell()
    }
    
    private func cellForContact(atIndexPath indexPath: IndexPath) -> CKAccountEditProfileContactCell {
        
        // dequeue account contact cell
        if let cell = tableView.dequeueReusableCell(
            withIdentifier: CKAccountEditProfileContactCell.identifier,
            for: indexPath) as? CKAccountEditProfileContactCell {
            cell.contactTextField.text = savingData.contact
            
            // text value
            cell.edittingChangedHandler = { text in
                if let text = text {
                    self.savingData.contact = text
                    self.updateControls()
                }
            }
            return cell
        }
        return CKAccountEditProfileContactCell()
    }
    
    private func updateControls() {
        // create button is enable or disable
        self.navigationItem.rightBarButtonItem?.isEnabled = savingData.isValidated()
    }
    
    
    private func titleForHeader(atSection section: Int) -> String {
        guard let section = Section(rawValue: section) else { return ""}
        
        switch section {
        case .avatarname:
            return ""
        case .displayname:
            return "Display name"
        case .career:
            return "What I do"
        case.contact:
            return "Contact"
        }
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
        self.saveData(self)
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
            return 60
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let view = CKRoomHeaderInSectionView.instance() {
            view.backgroundColor = CKColor.Background.tableView
            view.title = self.titleForHeader(atSection: section)
            return view
        }
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UILabel()
        view.backgroundColor = CKColor.Background.tableView
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
}

// MARK: - UITableViewDataSource

extension CKAccountProfileEditViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        self.updateSaveButtonStatus()
        return Section.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard let section = Section(rawValue: section) else { return 0 }
        
        // number rows in case
        switch section {
        case .avatarname: return 1
        case .displayname: return 1
        case .career: return 1
        case.contact: return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let section = Section(rawValue: indexPath.section) else { return CKAccountEditProfileBaseCell() }
        
        switch section {
        case .avatarname:
            
            // account profile avatar name cell
            return cellForAvatarPersonal(atIndexPath: indexPath)
        case .displayname:
            
            // account profile display name cell
            return cellForDisplayName(atIndexPath: indexPath)
        case .career:
            
            // account profile career cell
            return cellForCareer(atIndexPath: indexPath)
            
        case .contact:
            // account profile contact cell
            return cellForContact(atIndexPath: indexPath)
        }
    }
}



