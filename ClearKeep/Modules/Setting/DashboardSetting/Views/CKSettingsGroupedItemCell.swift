//
//  MembersCell.swift
//  FileXib
//
//  Created by Hiếu Nguyễn on 1/9/19.
//  Copyright © 2019 Hiếu Nguyễn. All rights reserved.
//

import UIKit

class CKSettingsGroupedItemCell: MXKTableViewCell {

    // MARK: - OUTLET
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var iconDetailImage: UIImageView!

    // MARK: - OVERRIDE
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.theme.backgroundColor = themeService.attrStream{ $0.primaryBgColor }
        self.titleLabel.theme.textColor = themeService.attrStream { $0.primaryTextColor }
        self.iconDetailImage.image = #imageLiteral(resourceName: "details_icon").withRenderingMode(.alwaysTemplate)
        self.iconImageView.theme.tintColor = themeService.attrStream{ $0.accessoryTblColor }
    }

}
