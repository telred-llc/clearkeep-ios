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

final class KeyBackupRecoverFromPassphraseViewController: UIViewController {    
    
    // MARK: - Properties
    let disposeBag = DisposeBag()
    
    // MARK: Outlets
    
    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBOutlet private weak var shieldImageView: UIImageView!
    
    @IBOutlet private weak var informationLabel: UILabel!        
    
    @IBOutlet private weak var passphraseTitleLabel: UILabel!
    @IBOutlet private weak var passphraseTextField: UITextField!
    @IBOutlet private weak var passphraseTextFieldBackgroundView: UIView!
    
    @IBOutlet private weak var passphraseVisibilityButton: UIButton!
    
    @IBOutlet private weak var recoverButtonBackgroundView: UIView!
    @IBOutlet private weak var recoverButton: UIButton!
    
    // MARK: Private
    
    private var viewModel: KeyBackupRecoverFromPassphraseViewModelType!
    private var keyboardAvoider: KeyboardAvoider?
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    
    // MARK: Public
    
    // MARK: - Setup
    
    class func instantiate(with viewModel: KeyBackupRecoverFromPassphraseViewModelType) -> KeyBackupRecoverFromPassphraseViewController {
        let viewController = StoryboardScene.KeyBackupRecoverFromPassphraseVC.initialScene.instantiate()
        viewController.viewModel = viewModel
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.title = CKLocalization.string(byKey: "key_backup_recover_title")
        self.vc_removeBackTitle()
        
        self.setupViews()
        self.keyboardAvoider = KeyboardAvoider(scrollViewContainerView: self.view, scrollView: self.scrollView)
        self.activityPresenter = ActivityIndicatorPresenter()
        self.errorPresenter = MXKErrorAlertPresentation()
        
        self.bindingTheme()
        
        self.viewModel.viewDelegate = self
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return themeService.attrs.statusBarStyle
    }
    
    // MARK: - Private
    
    private func setupViews() {
        let cancelBarButtonItem = MXKBarButtonItem(title: CKLocalization.string(byKey: "cancel"), style: .plain) { [weak self] in
            self?.viewModel.process(viewAction: .cancel)
        }
        
        self.navigationItem.rightBarButtonItem = cancelBarButtonItem
        
        self.scrollView.keyboardDismissMode = .interactive
        
        let shieldImage = Asset.Images.keyBackupLogo.image.withRenderingMode(.alwaysTemplate)
        self.shieldImageView.image = shieldImage
        
        let visibilityImage = Asset.Images.revealPasswordButton.image.withRenderingMode(.alwaysTemplate)
        self.passphraseVisibilityButton.setImage(visibilityImage, for: .normal)
        
        self.informationLabel.text = CKLocalization.string(byKey: "key_backup_recover_from_passphrase_info")
        
        self.passphraseTitleLabel.text = CKLocalization.string(byKey: "key_backup_recover_from_passphrase_passphrase_title")
        self.passphraseTextField.addTarget(self, action: #selector(passphraseTextFieldDidChange(_:)), for: .editingChanged)
        
        self.recoverButton.vc_enableMultiLinesTitle()
        self.recoverButton.setTitle(CKLocalization.string(byKey: "key_backup_recover_from_passphrase_recover_action"), for: .normal)
        
        self.updateRecoverButton()
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
            .bind({ $0.primaryBgColor }, to: self.passphraseTextFieldBackgroundView.rx.backgroundColor, self.recoverButtonBackgroundView.rx.backgroundColor)
            .bind({ $0.primaryTextColor }, to: self.informationLabel.rx.textColor, self.shieldImageView.rx.tintColor,self.passphraseTitleLabel.rx.textColor)
            .disposed(by: disposeBag)
        
        CKColor.applyStyle(onTextField: self.passphraseTextField)
        CKColor.applyStyle(onButton: self.passphraseVisibilityButton)
        CKColor.applyStyle(onButton: self.recoverButton)
        
        self.passphraseTextField.attributedPlaceholder = NSAttributedString(string: CKLocalization.string(byKey: "key_backup_recover_from_passphrase_passphrase_placeholder") , attributes: [.foregroundColor: themeService.attrs.placeholderTextColor])
    }
    

    
    private func updateRecoverButton() {
        self.recoverButton.isEnabled = self.viewModel.isFormValid
    }
    
    private func render(viewState: KeyBackupRecoverFromPassphraseViewState) {
        switch viewState {
        case .loading:
            self.renderLoading()
        case .loaded:
            self.renderLoaded()
        case .error(let error):
            self.render(error: error)
        }
    }
    
    private func renderLoading() {
        self.view.endEditing(true)
        self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
    }
    
    private func renderLoaded() {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
    }
    
    private func render(error: Error) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)

        if (error as NSError).domain == MXKeyBackupErrorDomain
            && (error as NSError).code == Int(MXKeyBackupErrorInvalidRecoveryKeyCode.rawValue) {

            self.errorPresenter.presentError(from: self, title: CKLocalization.string(byKey: "key_backup_recover_invalid_passphrase_title"), message: CKLocalization.string(byKey: "key_backup_recover_invalid_passphrase"), animated: true, handler: nil)
        } else {
            self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
        }
    }
    
    // MARK: - Actions
    
    @IBAction private func passphraseVisibilityButtonAction(_ sender: Any) {
        self.passphraseTextField.isSecureTextEntry = !self.passphraseTextField.isSecureTextEntry
    }
    
    @objc private func passphraseTextFieldDidChange(_ textField: UITextField) {
        self.viewModel.passphrase = textField.text
        self.updateRecoverButton()
    }
    
    @IBAction private func recoverButtonAction(_ sender: Any) {
        self.viewModel.process(viewAction: .recover)
    }
}

// MARK: - UITextFieldDelegate
extension KeyBackupRecoverFromPassphraseViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - KeyBackupRecoverFromPassphraseViewModelViewDelegate
extension KeyBackupRecoverFromPassphraseViewController: KeyBackupRecoverFromPassphraseViewModelViewDelegate {
    func keyBackupRecoverFromPassphraseViewModel(_ viewModel: KeyBackupRecoverFromPassphraseViewModelType, didUpdateViewState viewSate: KeyBackupRecoverFromPassphraseViewState) {
        self.render(viewState: viewSate)
    }
}
