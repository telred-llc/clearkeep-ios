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
    
    // MARK: - OVERRIDE
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageSettings.image = UIImage(named: "ic_room_settings")
        self.accessoryType = .disclosureIndicator
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
