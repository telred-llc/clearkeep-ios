//
//  AddPeopleCell.swift
//  FileXib
//
//  Created by Hiếu Nguyễn on 1/9/19.
//  Copyright © 2019 Hiếu Nguyễn. All rights reserved.
//

import UIKit

class CKRoomSettingsLeaveCell: CKRoomSettingsBaseCell {

    // MARK: - Outlet
    
    @IBOutlet weak var leaveButton: UIButton!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var iconDetailImage: UIImageView!
    
    // MARK: - OVERRIDE
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.accessoryType = .none
        self.leaveButton.setTitleColor(#colorLiteral(red: 0.8784313725, green: 0.3882352941, blue: 0.3882352941, alpha: 1), for: .normal)
        self.iconDetailImage.image = #imageLiteral(resourceName: "details_icon").withRenderingMode(.alwaysTemplate)
        self.iconDetailImage.tintColor = #colorLiteral(red: 0.8784313725, green: 0.3882352941, blue: 0.3882352941, alpha: 1)
        
        self.iconImageView.contentMode = .scaleAspectFit
        self.iconImageView.image = #imageLiteral(resourceName: "leave_room_edit_detail_room")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    // MARK: - PRIVATE
    
}
