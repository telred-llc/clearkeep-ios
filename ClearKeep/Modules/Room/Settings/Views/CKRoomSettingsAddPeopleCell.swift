//
//  AddPeopleCell.swift
//  FileXib
//
//  Created by Hiếu Nguyễn on 1/9/19.
//  Copyright © 2019 Hiếu Nguyễn. All rights reserved.
//

import UIKit

class CKRoomSettingsAddPeopleCell: UITableViewCell {

    // MARK: - Outlet
    
    @IBOutlet weak var btnAddUser: UIButton!
    @IBOutlet weak var imageAdd: UIImageView!
    
    // MARK: - CLASS VAR
    
    public class var identifier: String {
        return self.nibName
    }
    
    public class var nibName: String {
        return "CKRoomSettingsAddPeopleCell"
    }
    
    // MARK: - OVERRIDE
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageAdd.image = UIImage(named: "ic_room_add_user")
        self.accessoryType = .disclosureIndicator
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    // MARK: - PRIVATE
    
}
