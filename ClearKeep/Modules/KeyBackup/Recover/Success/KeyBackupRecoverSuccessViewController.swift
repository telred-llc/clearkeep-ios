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

protocol KeyBackupRecoverSuccessViewControllerDelegate: class {
    func KeyBackupRecoverSuccessViewControllerDidTapDone(_ keyBackupRecoverSuccessViewController: KeyBackupRecoverSuccessViewController)
}

final class KeyBackupRecoverSuccessViewController: UIViewController {
    
    // MARK: - Properties
    let disposeBag = DisposeBag()
    
    // MARK: Outlets
    
    @IBOutlet private weak var shieldImageView: UIImageView!
    
    @IBOutlet private weak var informationLabel: UILabel!
    
    @IBOutlet private weak var doneButtonBackgroundView: UIView!
    @IBOutlet private weak var doneButton: UIButton!
    
    // MARK: Private
    
//    private var theme: Theme!
    
    // MARK: Public
    
    weak var delegate: KeyBackupRecoverSuccessViewControllerDelegate?
    
    // MARK: - Setup
    
    class func instantiate() -> KeyBackupRecoverSuccessViewController {
        let viewController = StoryboardScene.KeyBackupRecoverSuccessVC.initialScene.instantiate()
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.title = CKLocalization.string(byKey: "key_backup_recover_title") 
        self.vc_removeBackTitle()
        
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
        let shieldImage = Asset.Images.keyBackupLogo.image.withRenderingMode(.alwaysTemplate)
        self.shieldImageView.image = shieldImage
        
        self.informationLabel.text = CKLocalization.string(byKey: "key_backup_recover_success_info")
        
        self.doneButton.vc_enableMultiLinesTitle()
        self.doneButton.setTitle(CKLocalization.string(byKey: "key_backup_recover_done_action"), for: .normal)
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
            .bind({ $0.primaryBgColor }, to: self.doneButtonBackgroundView.rx.backgroundColor)
            .bind({ $0.primaryTextColor }, to: self.shieldImageView.rx.tintColor, self.informationLabel.rx.textColor)
            .disposed(by: disposeBag)
    }
    
    @IBAction private func doneButtonAction(_ sender: Any) {
        self.delegate?.KeyBackupRecoverSuccessViewControllerDidTapDone(self)
    }
}
