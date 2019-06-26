//
//  AddPeopleCell.swift
//  FileXib
//
//  Created by Hiếu Nguyễn on 1/9/19.
//  Copyright © 2019 Hiếu Nguyễn. All rights reserved.
//

import UIKit

class CKRoomSettingsAddPeopleCell: CKRoomSettingsBaseCell {

    // MARK: - Outlet
    
    @IBOutlet weak var btnAddUser: UIButton!
    @IBOutlet weak var imageAdd: UIImageView!    
    
    // MARK: - OVERRIDE
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.accessoryType = .disclosureIndicator
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    // MARK: - PRIVATE
    
}
