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

final class KeyBackupSetupPassphraseViewController: UIViewController {
    
    // MARK: - Constants
    
    private enum Constants {
        static let animationDuration: TimeInterval = 0.3
    }
    
    // MARK: - Properties
    let disposeBag = DisposeBag()
    
    // MARK: Outlets

    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var informationLabel: UILabel!
    
    @IBOutlet private weak var formBackgroundView: UIView!
    
    @IBOutlet private weak var passphraseTitleLabel: UILabel!
    @IBOutlet private weak var passphraseTextField: UITextField!
    
    @IBOutlet private weak var passphraseAdditionalInfoView: UIView!
    @IBOutlet private weak var passphraseStrengthView: PasswordStrengthView!
    @IBOutlet private weak var passphraseAdditionalLabel: UILabel!
    
    @IBOutlet private weak var formSeparatorView: UIView!
    
    @IBOutlet private weak var confirmPassphraseTitleLabel: UILabel!
    @IBOutlet private weak var confirmPassphraseTextField: UITextField!
    
    @IBOutlet private weak var confirmPassphraseAdditionalInfoView: UIView!
    @IBOutlet private weak var confirmPassphraseAdditionalLabel: UILabel!
    
    @IBOutlet private weak var setPassphraseButtonBackgroundView: UIView!
    @IBOutlet private weak var setPassphraseButton: UIButton!
    
    // MARK: Private
    
    private var isFirstViewAppearing: Bool = true
    private var isPassphraseTextFieldEditedOnce: Bool = false
    private var isConfirmPassphraseTextFieldEditedOnce: Bool = false
    private var keyboardAvoider: KeyboardAvoider?
    private var viewModel: KeyBackupSetupPassphraseViewModelType!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    private weak var skipAlertController: UIAlertController?
    
    // MARK: - Setup
    
    class func instantiate(with viewModel: KeyBackupSetupPassphraseViewModelType) -> KeyBackupSetupPassphraseViewController {
        let viewController = StoryboardScene.KeyBackupSetupPassphraseVC.initialScene.instantiate()
        viewController.viewModel = viewModel
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.title = CKLocalization.string(byKey: "key_backup_setup_title") 
        self.vc_removeBackTitle()
        
        self.setupViews()
        self.keyboardAvoider = KeyboardAvoider(scrollViewContainerView: self.view, scrollView: self.scrollView)
        self.activityPresenter = ActivityIndicatorPresenter()
        self.errorPresenter = MXKErrorAlertPresentation()
        
        self.bindingTheme()
        self.viewModel.viewDelegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.keyboardAvoider?.startAvoiding()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.isFirstViewAppearing {
            self.isFirstViewAppearing = false
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.view.endEditing(true)
        self.keyboardAvoider?.stopAvoiding()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if self.isFirstViewAppearing {
            // Workaround to layout passphraseStrengthView corner radius
            self.passphraseStrengthView.setNeedsLayout()
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return themeService.attrs.statusBarStyle
    }
    
    // MARK: - Private
    
    private func setupViews() {
        let cancelBarButtonItem = MXKBarButtonItem(title: CKLocalization.string(byKey: "cancel"), style: .plain) { [weak self] in
            self?.cancelButtonAction()
        }
        
        self.navigationItem.rightBarButtonItem = cancelBarButtonItem
        
        self.scrollView.keyboardDismissMode = .interactive
        
        self.titleLabel.text = CKLocalization.string(byKey: "key_backup_setup_passphrase_title")
        self.informationLabel.text = CKLocalization.string(byKey: "key_backup_setup_passphrase_info")
        
        self.passphraseTitleLabel.text = CKLocalization.string(byKey: "key_backup_setup_passphrase_passphrase_title")
        self.passphraseTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        self.passphraseStrengthView.strength = self.viewModel.passphraseStrength
        self.passphraseAdditionalInfoView.isHidden = true
        
        self.confirmPassphraseTitleLabel.text = CKLocalization.string(byKey: "key_backup_setup_passphrase_confirm_passphrase_title")
        self.confirmPassphraseTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        self.confirmPassphraseAdditionalInfoView.isHidden = true
        
        self.setPassphraseButton.vc_enableMultiLinesTitle()
        self.setPassphraseButton.setTitle(CKLocalization.string(byKey: "key_backup_setup_passphrase_set_passphrase_action"), for: .normal)
        
        self.updateSetPassphraseButton()
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
            .bind({ $0.primaryBgColor }, to: self.formBackgroundView.rx.backgroundColor, self.setPassphraseButton.rx.backgroundColor)
            .bind({ $0.primaryTextColor }, to: self.titleLabel.rx.textColor, self.informationLabel.rx.textColor, self.passphraseTitleLabel.rx.textColor, self.confirmPassphraseTitleLabel.rx.textColor)
            .bind({ $0.separatorColor }, to: self.formSeparatorView.rx.backgroundColor)
            .disposed(by: disposeBag)
          
        CKColor.applyStyle(onTextField: self.passphraseTextField)
        CKColor.applyStyle(onTextField: self.confirmPassphraseTextField)
        CKColor.applyStyle(onButton: self.setPassphraseButton)
        
        self.passphraseTextField.attributedPlaceholder = NSAttributedString(string: CKLocalization.string(byKey: "key_backup_setup_passphrase_passphrase_placeholder"), attributes: [.foregroundColor: themeService.attrs.placeholderTextColor])
        self.updatePassphraseAdditionalLabel()
        
        self.confirmPassphraseTextField.attributedPlaceholder = NSAttributedString(string: CKLocalization.string(byKey: "key_backup_setup_passphrase_confirm_passphrase_title"), attributes: [.foregroundColor: themeService.attrs.placeholderTextColor])
        self.updateConfirmPassphraseAdditionalLabel()
    }
    
    private func showPassphraseAdditionalInfo(animated: Bool) {
        guard self.passphraseAdditionalInfoView.isHidden else {
            return
        }
        
        UIView.animate(withDuration: Constants.animationDuration) {
            self.passphraseAdditionalInfoView.isHidden = false
        }
    }
    
    private func showConfirmPassphraseAdditionalInfo(animated: Bool) {
        guard self.confirmPassphraseAdditionalInfoView.isHidden else {
            return
        }
        
        UIView.animate(withDuration: Constants.animationDuration) {
            self.confirmPassphraseAdditionalInfoView.isHidden = false
        }
    }
    
    private func hideConfirmPassphraseAdditionalInfo(animated: Bool) {
        guard self.confirmPassphraseAdditionalInfoView.isHidden == false else {
            return
        }
        
        UIView.animate(withDuration: Constants.animationDuration) {
            self.confirmPassphraseAdditionalInfoView.isHidden = true
        }
    }
    
    private func updatePassphraseStrengthView() {
        self.passphraseStrengthView.strength = self.viewModel.passphraseStrength
    }
    
    private func updatePassphraseAdditionalLabel() {
        
        let text: String
        let textColor: UIColor
        
        if self.viewModel.isPassphraseValid {
            text = CKLocalization.string(byKey: "key_backup_setup_passphrase_passphrase_valid")
            textColor = CKColor.Text.tint
        } else {
            text = CKLocalization.string(byKey: "key_backup_setup_passphrase_passphrase_invalid")
            textColor = UIColor.red
        }
        
        self.passphraseAdditionalLabel.text = text
        self.passphraseAdditionalLabel.textColor = textColor
    }
    
    private func updateConfirmPassphraseAdditionalLabel() {
        
        let text: String
        let textColor: UIColor
        
        if self.viewModel.isConfirmPassphraseValid {
            text = CKLocalization.string(byKey: "key_backup_setup_passphrase_confirm_passphrase_valid")
            textColor = CKColor.Text.tint
        } else {
            text = CKLocalization.string(byKey: "key_backup_setup_passphrase_confirm_passphrase_invalid")
            textColor = UIColor.red
        }
        
        self.confirmPassphraseAdditionalLabel.text = text
        self.confirmPassphraseAdditionalLabel.textColor = textColor
    }
    
    private func updateSetPassphraseButton() {
        self.setPassphraseButton.isEnabled = self.viewModel.isFormValid
    }
    
    private func render(viewState: KeyBackupSetupPassphraseViewState) {
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
        self.hideSkipAlert(animated: false)
        self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }
    
    private func showSkipAlert() {
        guard self.skipAlertController == nil else {
            return
        }
        
        let alertController = UIAlertController(title: CKLocalization.string(byKey: "key_backup_setup_skip_alert_title"),
                                                message: CKLocalization.string(byKey: "key_backup_setup_skip_alert_message"),
                                                preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: CKLocalization.string(byKey: "continue"), style: .cancel, handler: { action in
            self.viewModel.process(viewAction: .skipAlertContinue)
        }))
        
        alertController.addAction(UIAlertAction(title: CKLocalization.string(byKey: "key_backup_setup_skip_alert_skip_action"), style: .default, handler: { action in
            self.viewModel.process(viewAction: .skipAlertSkip)
        }))
        
        self.present(alertController, animated: true, completion: nil)
        self.skipAlertController = alertController
    }
    
    private func hideSkipAlert(animated: Bool) {
        self.skipAlertController?.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Actions
    
    @IBAction private func passphraseVisibilityButtonAction(_ sender: Any) {
        guard self.isPassphraseTextFieldEditedOnce else {
            return
        }
        self.passphraseTextField.isSecureTextEntry = !self.passphraseTextField.isSecureTextEntry
        // TODO: Use this when project will be migrated to Swift 4.2
        // self.passphraseTextField.isSecureTextEntry.toggle()
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        
        if textField == self.passphraseTextField {
            self.viewModel.passphrase = textField.text
            
            self.updatePassphraseAdditionalLabel()
            self.updatePassphraseStrengthView()
            
            // Show passphrase additional info at first character entered
            if self.isPassphraseTextFieldEditedOnce == false && textField.text?.isEmpty == false {
                self.isPassphraseTextFieldEditedOnce = true
                self.showPassphraseAdditionalInfo(animated: true)
            }
        } else {
            self.viewModel.confirmPassphrase = textField.text
        }
        
        // Show confirm passphrase additional info if needed
        self.updateConfirmPassphraseAdditionalLabel()
        if self.viewModel.confirmPassphrase?.isEmpty == false && self.viewModel.isPassphraseValid {
            self.showConfirmPassphraseAdditionalInfo(animated: true)
        } else {
            self.hideConfirmPassphraseAdditionalInfo(animated: true)
        }
        
        // Enable validate button if form is valid
        self.updateSetPassphraseButton()
    }
    
    @IBAction private func setPassphraseButtonAction(_ sender: Any) {
        self.viewModel.process(viewAction: .setupPassphrase)
    }
     
    private func cancelButtonAction() {
        self.viewModel.process(viewAction: .skip)
    }
}

// MARK: - UITextFieldDelegate
extension KeyBackupSetupPassphraseViewController: UITextFieldDelegate {
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.textFieldDidChange(textField)
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == self.passphraseTextField {
           self.confirmPassphraseTextField.becomeFirstResponder()
        } else {
           textField.resignFirstResponder()
        }
        
        return true
    }
}

// MARK: - KeyBackupSetupPassphraseViewModelViewDelegate
extension KeyBackupSetupPassphraseViewController: KeyBackupSetupPassphraseViewModelViewDelegate {
    func keyBackupSetupPassphraseViewModel(_ viewModel: KeyBackupSetupPassphraseViewModelType, didUpdateViewState viewSate: KeyBackupSetupPassphraseViewState) {
        self.render(viewState: viewSate)
    }
    
    func keyBackupSetupPassphraseViewModelShowSkipAlert(_ viewModel: KeyBackupSetupPassphraseViewModelType) {
        self.showSkipAlert()
    }
}
