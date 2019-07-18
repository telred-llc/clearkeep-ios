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

@objc protocol KeyBackupBannerCellDelegate: class {
    func keyBackupBannerCellDidTapCloseAction(_ cell: KeyBackupBannerCell)
}

@objcMembers
final class KeyBackupBannerCell: MXKTableViewCell {
    
    // MARK: - Properties
    let disposeBag = DisposeBag()
    
    // MARK: Outlets

    @IBOutlet private weak var shieldImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var closeButton: UIButton!
    
    // MARK: Public
    
    weak var delegate: KeyBackupBannerCellDelegate?
    
    // MARK: - Overrides
    
    override class func defaultReuseIdentifier() -> String {
        return String(describing: self)
    }
    
    override class func nib() -> UINib {
        return UINib(nibName: String(describing: self), bundle: nil)
    }
    
    override func customizeRendering() {
        super.customizeRendering()
        
        themeService.rx
            .bind({ $0.primaryTextColor }, to: self.shieldImageView.rx.tintColor, self.closeButton.rx.tintColor, self.titleLabel.rx.textColor)
            .disposed(by: disposeBag)
        self.subtitleLabel.textColor = CKColor.Text.tint
    }
    
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let shieldImage = Asset.Images.keyBackupLogo.image.withRenderingMode(.alwaysTemplate)
        self.shieldImageView.image = shieldImage
        
        let closeImage = Asset.Images.closeBanner.image.withRenderingMode(.alwaysTemplate)
        self.closeButton.setImage(closeImage, for: .normal)
    }
    
    // MARK: - Public
    
    func configure(for banner: KeyBackupBanner) {
        
        let title: String?
        let subtitle: String?
        
        switch banner {
        case .setup:
            title = CKLocalization.string(byKey: "key_backup_setup_banner_title")
            subtitle = CKLocalization.string(byKey: "key_backup_setup_banner_subtitle")
        case .recover:
            title = CKLocalization.string(byKey: "key_backup_recover_banner_title")
            subtitle = CKLocalization.string(byKey: "key_backup_recover_connent_banner_subtitle")
        case .none:
            title = nil
            subtitle = nil
        }
        
        self.titleLabel.text = title
        self.subtitleLabel.text = subtitle
    }
    
    // MARK: - Actions
    
    @IBAction private func closeButtonAction(_ sender: Any) {
        self.delegate?.keyBackupBannerCellDidTapCloseAction(self)
    }
}
