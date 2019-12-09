//
//  CKSettingDarkModeCell.swift
//  Riot
//
//  Created by Sinbad Flyce on 6/20/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

class CKSettingDarkModeCell: UITableViewCell {

    // MARK: - OUTLET
    @IBOutlet weak var switchView: UISwitch!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!

    var disposeBag = DisposeBag()

    // MARK: - OVERRIDE
    override func awakeFromNib() {
        super.awakeFromNib()
        self.theme.backgroundColor = themeService.attrStream{ $0.primaryBgColor }
        self.titleLabel.theme.textColor = themeService.attrStream { $0.primaryTextColor }
        self.switchView.theme.onTintColor = themeService.attrStream { $0.navBarTintColor }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
}
