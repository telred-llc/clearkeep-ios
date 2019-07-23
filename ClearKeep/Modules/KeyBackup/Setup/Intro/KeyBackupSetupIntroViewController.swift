/*
 Copyright 2019 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import UIKit

protocol KeyBackupSetupIntroViewControllerDelegate: class {
    func keyBackupSetupIntroViewControllerDidTapSetupAction(_ keyBackupSetupIntroViewController: KeyBackupSetupIntroViewController)
    func keyBackupSetupIntroViewControllerDidCancel(_ keyBackupSetupIntroViewController: KeyBackupSetupIntroViewController)
}

final class KeyBackupSetupIntroViewController: UIViewController {
    
    // MARK: - Properties
    let disposeBag = DisposeBag()
    
    // MARK: Outlets
    
    @IBOutlet private weak var keyBackupLogoImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var informationLabel: UILabel!
    
    @IBOutlet private weak var setUpButtonBackgroundView: UIView!
    @IBOutlet private weak var setUpButton: UIButton! 
    
    // MARK: Private
    
    private var isABackupAlreadyExists: Bool = false
    private var encryptionKeysExportPresenter: EncryptionKeysExportPresenter?
    
    private var showManualExport: Bool {
        return self.encryptionKeysExportPresenter != nil
    }
    
    // MARK: Public
    
    weak var delegate: KeyBackupSetupIntroViewControllerDelegate?
    
    // MARK: - Setup
    
    class func instantiate(isABackupAlreadyExists: Bool, encryptionKeysExportPresenter: EncryptionKeysExportPresenter?) -> KeyBackupSetupIntroViewController {
        let viewController = StoryboardScene.KeyBackupSetupIntroVC.initialScene.instantiate()
        viewController.isABackupAlreadyExists = isABackupAlreadyExists
        viewController.encryptionKeysExportPresenter = encryptionKeysExportPresenter
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.title = CKLocalization.string(byKey: "key_backup_setup_title")
        self.vc_removeBackTitle()
        
        self.setupViews()
        self.bindingTheme()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return themeService.attrs.statusBarStyle
    }
    
    // MARK: - Private
    
    private func setupViews() {
        let cancelBarButtonItem = MXKBarButtonItem(title: CKLocalization.string(byKey: "cancel"), style: .plain) { [weak self] in
            self?.showSkipAlert()
        }
        self.navigationItem.rightBarButtonItem = cancelBarButtonItem
        
        let keybackupLogoImage = Asset.Images.keyBackupLogo.image.withRenderingMode(.alwaysTemplate)
        self.keyBackupLogoImageView.image = keybackupLogoImage
        
        self.titleLabel.text = CKLocalization.string(byKey: "key_backup_setup_intro_title")
        self.informationLabel.text = CKLocalization.string(byKey: "key_backup_setup_intro_info")
        
        let setupTitle = self.isABackupAlreadyExists ? CKLocalization.string(byKey: "key_backup_setup_intro_setup_connect_action_with_existing_backup") : CKLocalization.string(byKey: "key_backup_setup_intro_setup_action_without_existing_backup")
        
        self.setUpButton.setTitle(setupTitle, for: .normal)
    }
    
    private func bindingTheme() {
        // Binding navigation bar color
        themeService.attrsStream.subscribe(onNext: { [weak self] (theme) in
            if let navigationBar = self?.navigationController?.navigationBar {
                navigationBar.tintColor = themeService.attrs.primaryTextColor
                navigationBar.titleTextAttributes = [
                    NSAttributedString.Key.foregroundColor: themeService.attrs.primaryTextColor
                ]
                navigationBar.barTintColor = themeService.attrs.primaryBgColor
                
                // The navigation bar needs to be opaque so that its background color is the expected one
                navigationBar.isTranslucent = false
            }
        }).disposed(by: disposeBag)
        
        themeService.rx
            .bind({ $0.secondBgColor }, to: self.view.rx.backgroundColor)
            .bind({ $0.primaryBgColor }, to: self.setUpButtonBackgroundView.rx.backgroundColor)
            .bind({ $0.primaryTextColor }, to: self.keyBackupLogoImageView.rx.tintColor, self.titleLabel.rx.textColor, self.informationLabel.rx.textColor)
            .disposed(by: disposeBag)
        
        CKColor.applyStyle(onButton: self.setUpButton)
    }
    
    private func showSkipAlert() {
        
        let alertController = UIAlertController(title: CKLocalization.string(byKey: "key_backup_setup_skip_alert_title"),
                                                message: CKLocalization.string(byKey: "key_backup_setup_skip_alert_message"),
                                                preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: CKLocalization.string(byKey: "continue"), style: .cancel, handler: { action in 
        }))
        alertController.addAction(UIAlertAction(title: CKLocalization.string(byKey: "key_backup_setup_skip_alert_skip_action"), style: .default, handler: { action in
            self.delegate?.keyBackupSetupIntroViewControllerDidCancel(self)
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Actions
    
    @IBAction private func validateButtonAction(_ sender: Any) {
        self.delegate?.keyBackupSetupIntroViewControllerDidTapSetupAction(self)
    }
}
