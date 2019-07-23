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

protocol KeyBackupSetupSuccessFromPassphraseViewControllerDelegate: class {
    func keyBackupSetupSuccessFromPassphraseViewControllerDidTapDoneAction(_ viewController: KeyBackupSetupSuccessFromPassphraseViewController)
}

final class KeyBackupSetupSuccessFromPassphraseViewController: UIViewController {    
    
    // MARK: - Properties
    let disposeBag = DisposeBag()
    
    // MARK: Outlets
    
    @IBOutlet private weak var keyBackupLogoImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var informationLabel: UILabel!
    
    @IBOutlet private weak var doneButtonBackgroundView: UIView!
    @IBOutlet private weak var doneButton: UIButton!
    
    // MARK: Private
    
    private var recoveryKey: String!
    
    // MARK: Public
    
    weak var delegate: KeyBackupSetupSuccessFromPassphraseViewControllerDelegate?
    
    // MARK: - Setup
    
    class func instantiate(with recoveryKey: String) -> KeyBackupSetupSuccessFromPassphraseViewController {
        let viewController = StoryboardScene.KeyBackupSetupSuccessFromPassphraseVC.initialScene.instantiate()
        viewController.recoveryKey = recoveryKey
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.title = CKLocalization.string(byKey: "key_backup_setup_title") 
        
        self.setupViews()
        self.bindingTheme()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide back button
        self.navigationItem.setHidesBackButton(true, animated: animated)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return themeService.attrs.statusBarStyle
    }
    
    // MARK: - Private
    
    private func setupViews() {
        
        let keybackupLogoImage = Asset.Images.keyBackupLogo.image.withRenderingMode(.alwaysTemplate)
        self.keyBackupLogoImageView.image = keybackupLogoImage
        
        self.titleLabel.text = CKLocalization.string(byKey: "key_backup_setup_success_title")
        self.informationLabel.text = CKLocalization.string(byKey: "key_backup_setup_success_from_passphrase_info")
        
        self.doneButton.setTitle(CKLocalization.string(byKey: "key_backup_setup_success_from_passphrase_done_action"), for: .normal)
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
            .bind({ $0.secondBgColor }, to: self.view.rx.backgroundColor, self.doneButtonBackgroundView.rx.backgroundColor)
            .bind({ $0.primaryTextColor }, to: self.keyBackupLogoImageView.rx.tintColor, self.titleLabel.rx.textColor, self.informationLabel.rx.textColor)
            .disposed(by: disposeBag)
        
        CKColor.applyStyle(onButton: self.doneButton)
    }
    
    @IBAction private func doneButtonAction(_ sender: Any) {
        self.delegate?.keyBackupSetupSuccessFromPassphraseViewControllerDidTapDoneAction(self)
    }
}
