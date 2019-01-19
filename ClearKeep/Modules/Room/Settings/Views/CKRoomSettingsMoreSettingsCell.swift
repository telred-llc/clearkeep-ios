//
//  MoreSettingsCell.swift
//  FileXib
//
//  Created by Hiếu Nguyễn on 1/9/19.
//  Copyright © 2019 Hiếu Nguyễn. All rights reserved.
//

import UIKit

class CKRoomSettingsMoreSettingsCell: UITableViewCell {

    // MARK: - OUTLET
    
    @IBOutlet weak var btnSetting: UIButton!
    @IBOutlet weak var imageSettings: UIImageView!
    
    // MARK: - CLASS VAR
    
    public class var identifier: String {
        return self.nibName
    }
    
    public class var nibName: String {
        return "CKRoomSettingsMoreSettingsCell"
    }
    
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
