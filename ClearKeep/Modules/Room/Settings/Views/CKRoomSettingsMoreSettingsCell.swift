//
//  MoreSettingsCell.swift
//  FileXib
//
//  Created by Hiếu Nguyễn on 1/9/19.
//  Copyright © 2019 Hiếu Nguyễn. All rights reserved.
//

import UIKit

class CKRoomSettingsMoreSettingsCell: CKRoomSettingsBaseCell {

    // MARK: - OUTLET
    
    @IBOutlet weak var btnSetting: UIButton!
    @IBOutlet weak var imageSettings: UIImageView!    
    @IBOutlet weak var detailIconImage: UIImageView!
    
    // MARK: - OVERRIDE
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.accessoryType = .none
        self.detailIconImage.image = #imageLiteral(resourceName: "details_icon").withRenderingMode(.alwaysTemplate)
        self.detailIconImage.theme.tintColor = themeService.attrStream{ $0.accessoryTblColor }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.detailIconImage.theme.tintColor = themeService.attrStream{ $0.accessoryTblColor }
    }
}
