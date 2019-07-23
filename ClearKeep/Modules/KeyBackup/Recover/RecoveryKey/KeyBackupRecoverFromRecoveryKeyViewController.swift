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
import MobileCoreServices

final class KeyBackupRecoverFromRecoveryKeyViewController: UIViewController {
    
    // MARK: - Properties
    let disposeBag = DisposeBag()
    
    // MARK: Outlets
    
    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBOutlet private weak var shieldImageView: UIImageView!
    
    @IBOutlet private weak var informationLabel: UILabel!
    
    @IBOutlet private weak var recoveryKeyTitleLabel: UILabel!
    @IBOutlet private weak var recoveryKeyTextField: UITextField!
    @IBOutlet private weak var recoveryKeyTextFieldBackgroundView: UIView!
    
    @IBOutlet private weak var importFileButton: UIButton!
    
    @IBOutlet private weak var unknownRecoveryKeyButton: UIButton!
    
    @IBOutlet private weak var recoverButtonBackgroundView: UIView!
    @IBOutlet private weak var recoverButton: UIButton!
    
    // MARK: Private
    
    private var viewModel: KeyBackupRecoverFromRecoveryKeyViewModelType!
    private var keyboardAvoider: KeyboardAvoider?
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    private weak var skipAlertController: UIAlertController?
    
    // MARK: Public
    
    // MARK: - Setup
    
    class func instantiate(with viewModel: KeyBackupRecoverFromRecoveryKeyViewModelType) -> KeyBackupRecoverFromRecoveryKeyViewController {
        let viewController = StoryboardScene.KeyBackupRecoverFromRecoveryKeyVC.initialScene.instantiate()
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
        
        self.viewModel.viewDelegate = self
        
        self.bindingTheme()
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
        
        let shieldImage = Asset.Images.keyBackupLogo.image.withRenderingMode(.alwaysTemplate)
        self.shieldImageView.image = shieldImage
        
        self.informationLabel.text = CKLocalization.string(byKey: "key_backup_recover_from_recovery_key_info")
        
        self.recoveryKeyTitleLabel.text = CKLocalization.string(byKey: "key_backup_recover_from_recovery_key_recovery_key_title")
        self.recoveryKeyTextField.addTarget(self, action: #selector(recoveryKeyTextFieldDidChange(_:)), for: .editingChanged)
        
        let importFileImage = Asset.Images.importFilesButton.image.withRenderingMode(.alwaysTemplate)
        self.importFileButton.setImage(importFileImage, for: .normal)
        
        self.unknownRecoveryKeyButton.vc_enableMultiLinesTitle()
        self.unknownRecoveryKeyButton.setTitle(CKLocalization.string(byKey: "key_backup_recover_from_recovery_key_lost_recovery_key_action"), for: .normal)
        // Interaction is disabled for the moment
        self.unknownRecoveryKeyButton.isUserInteractionEnabled = false
        
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
            .bind({ $0.primaryBgColor }, to: self.recoveryKeyTextFieldBackgroundView.rx.backgroundColor, self.recoverButtonBackgroundView.rx.backgroundColor)
            .bind({ $0.primaryTextColor }, to: self.informationLabel.rx.textColor, self.shieldImageView.rx.tintColor, self.recoveryKeyTitleLabel.rx.textColor, self.unknownRecoveryKeyButton.rx.titleColor(for: .normal))
            .disposed(by: disposeBag)
        
        CKColor.applyStyle(onTextField: self.recoveryKeyTextField)
        CKColor.applyStyle(onButton: self.importFileButton)
        CKColor.applyStyle(onButton: self.recoverButton)

        self.recoveryKeyTextField.attributedPlaceholder = NSAttributedString(string: CKLocalization.string(byKey: "key_backup_recover_from_recovery_key_recovery_key_placeholder"), attributes: [.foregroundColor: themeService.attrs.placeholderTextColor])
    }
    
    private func updateRecoverButton() {
        self.recoverButton.isEnabled = self.viewModel.isFormValid
    }
    
    private func render(viewState: KeyBackupRecoverFromRecoveryKeyViewState) {
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

            self.errorPresenter.presentError(from: self, title: CKLocalization.string(byKey: "key_backup_recover_invalid_recovery_key_title"), message: CKLocalization.string(byKey: "key_backup_recover_invalid_recovery_key"), animated: true, handler: nil)
        } else {
            self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
        }
    }
    
    private func showFileSelection() {
        // Show only text documents
        let documentPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeText as String], in: .import)
        documentPicker.delegate = self
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    private func importRecoveryKey(from url: URL) {
        if let recoveryKey = self.getDocumentContent(from: url) {
            self.recoveryKeyTextField.text = recoveryKey
            self.recoveryKeyTextFieldDidChange(self.recoveryKeyTextField)
        } else {
            self.errorPresenter.presentGenericError(from: self, animated: true, handler: nil)
        }
    }
    
    private func getDocumentContent(from documentURL: URL) -> String? {
        let documentContent: String?
        
        do {
            documentContent = try String(contentsOf: documentURL)
        } catch {
            documentContent = nil
        }
        
        return documentContent
    }
    
    // MARK: - Actions
    
    private func cancelButtonAction() {
        self.viewModel.process(viewAction: .cancel)
    }
    
    @IBAction private func importFileButtonAction(_ sender: Any) {
        self.showFileSelection()
    }
    
    @objc private func recoveryKeyTextFieldDidChange(_ textField: UITextField) {
        self.viewModel.recoveryKey = textField.text
        self.updateRecoverButton()
    }
    
    @IBAction private func usePassphraseButtonAction(_ sender: Any) {
        self.viewModel.process(viewAction: .recover)
    }
    
    @IBAction private func unknownPassphraseButtonAction(_ sender: Any) {
        self.viewModel.process(viewAction: .unknownRecoveryKey)
    }
}

// MARK: - UITextFieldDelegate
extension KeyBackupRecoverFromRecoveryKeyViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - KeyBackupRecoverFromRecoveryKeyViewModelViewDelegate
extension KeyBackupRecoverFromRecoveryKeyViewController: KeyBackupRecoverFromRecoveryKeyViewModelViewDelegate {
    func keyBackupRecoverFromPassphraseViewModel(_ viewModel: KeyBackupRecoverFromRecoveryKeyViewModelType, didUpdateViewState viewSate: KeyBackupRecoverFromRecoveryKeyViewState) {
        self.render(viewState: viewSate)
    }
}

// MARK: - UIDocumentPickerDelegate
extension KeyBackupRecoverFromRecoveryKeyViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let documentUrl = urls.first else {
            return
        }
        self.importRecoveryKey(from: documentUrl)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        self.importRecoveryKey(from: url)
    }
}
