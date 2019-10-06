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

@objc protocol SignOutAlertPresenterDelegate: class {
    func signOutAlertPresenterDidTapSignOutAction(_ presenter: SignOutAlertPresenter)
    func signOutAlertPresenterDidTapBackupAction(_ presenter: SignOutAlertPresenter)
}

@objcMembers
final class SignOutAlertPresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private weak var presentingViewController: UIViewController?
    private weak var sourceView: UIView?
    
    // MARK: Public
    
    weak var delegate: SignOutAlertPresenterDelegate?
    
    // MARK: - Public
    
    func present(for keyBackupState: MXKeyBackupState,
                 areThereKeysToBackup: Bool,
                 from viewController: UIViewController,
                 sourceView: UIView?,
                 animated: Bool) {
        self.sourceView = sourceView
        self.presentingViewController = viewController
        
        switch keyBackupState {
        case MXKeyBackupStateUnknown, MXKeyBackupStateDisabled, MXKeyBackupStateCheckingBackUpOnHomeserver:
            self.presentNonExistingBackupAlert(animated: animated)
        case MXKeyBackupStateWillBackUp, MXKeyBackupStateBackingUp:
            self.presentBackupInProgressAlert(animated: animated)
        default:
            self.presentExistingBackupAlert(animated: animated)
        }
    }
    
    // MARK: - Private
    
    private func presentExistingBackupAlert(animated: Bool) {
        let alertContoller = UIAlertController(title: CKLocalization.string(byKey: "sign_out_existing_key_backup_alert_title"), message: nil, preferredStyle: .actionSheet)
        
        let signoutAction = UIAlertAction(title: CKLocalization.string(byKey: "sign_out_existing_key_backup_alert_sign_out_action"), style: .destructive) { (_) in
            self.delegate?.signOutAlertPresenterDidTapSignOutAction(self)
        }
        
        let cancelAction = UIAlertAction(title: CKLocalization.string(byKey: "cancel"), style: .cancel, handler: nil)
        
        alertContoller.addAction(signoutAction)
        alertContoller.addAction(cancelAction)
        
        self.present(alertController: alertContoller, animated: animated)
    }
    
    private func presentNonExistingBackupAlert(animated: Bool) {
        let alertContoller = UIAlertController(title: CKLocalization.string(byKey: "sign_out_non_existing_key_backup_alert_title"), message: nil, preferredStyle: .actionSheet)
        
        let doNotWantKeyBackupAction = UIAlertAction(title: CKLocalization.string(byKey: "sign_out_non_existing_key_backup_alert_discard_key_backup_action"), style: .destructive) { (_) in
            self.presentNonExistingBackupSignOutConfirmationAlert(animated: true)
        }
        
        let setUpKeyBackupAction = UIAlertAction(title: CKLocalization.string(byKey: "sign_out_non_existing_key_backup_alert_setup_key_backup_action"), style: .default) { (_) in
            self.delegate?.signOutAlertPresenterDidTapBackupAction(self)
        }
        
        let cancelAction = UIAlertAction(title: CKLocalization.string(byKey: "cancel"), style: .cancel, handler: nil)
        
        alertContoller.addAction(doNotWantKeyBackupAction)
        alertContoller.addAction(setUpKeyBackupAction)
        alertContoller.addAction(cancelAction)
        
        self.present(alertController: alertContoller, animated: animated)
    }
    
    private func presentNonExistingBackupSignOutConfirmationAlert(animated: Bool) {
        let alertContoller = UIAlertController(title: CKLocalization.string(byKey: "sign_out_non_existing_key_backup_sign_out_confirmation_alert_title"), message: CKLocalization.string(byKey: "sign_out_non_existing_key_backup_sign_out_confirmation_alert_message"), preferredStyle: .alert)
        
        let signOutAction = UIAlertAction(title: CKLocalization.string(byKey: "sign_out_non_existing_key_backup_sign_out_confirmation_alert_sign_out_action"), style: .destructive) { (_) in
            self.delegate?.signOutAlertPresenterDidTapSignOutAction(self)
        }
        
        let setUpKeyBackupAction = UIAlertAction(title: CKLocalization.string(byKey: "sign_out_non_existing_key_backup_sign_out_confirmation_alert_backup_action"), style: .default) { (_) in
            self.delegate?.signOutAlertPresenterDidTapBackupAction(self)
        }
        
        alertContoller.addAction(signOutAction)
        alertContoller.addAction(setUpKeyBackupAction)
        
        self.present(alertController: alertContoller, animated: animated)
    }
    
    private func presentBackupInProgressAlert(animated: Bool) {
        let alertContoller = UIAlertController(title: CKLocalization.string(byKey: "sign_out_key_backup_in_progress_alert_title"), message: nil, preferredStyle: .actionSheet)
        
        let discardKeyBackupAction = UIAlertAction(title: CKLocalization.string(byKey: "sign_out_key_backup_in_progress_alert_discard_key_backup_action"), style: .destructive) { (_) in
            self.delegate?.signOutAlertPresenterDidTapSignOutAction(self)
        }
        
        let cancelAction = UIAlertAction(title: CKLocalization.string(byKey: "sign_out_key_backup_in_progress_alert_cancel_action"), style: .cancel, handler: nil)
        
        alertContoller.addAction(discardKeyBackupAction)
        alertContoller.addAction(cancelAction)
        
        self.present(alertController: alertContoller, animated: animated)
    }
    
    private func present(alertController: UIAlertController, animated: Bool) {
        
        // Configure source view when alert controller is presented with a popover
        if let sourceView = self.sourceView, let popoverPresentationController = alertController.popoverPresentationController {
            popoverPresentationController.sourceView = sourceView
            popoverPresentationController.sourceRect = sourceView.bounds
            popoverPresentationController.permittedArrowDirections = [.down, .up]
        }
        
        self.presentingViewController?.present(alertController, animated: animated, completion: nil)
    }
}
