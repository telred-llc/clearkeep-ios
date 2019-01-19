//
//  MembersCell.swift
//  FileXib
//
//  Created by Hiếu Nguyễn on 1/9/19.
//  Copyright © 2019 Hiếu Nguyễn. All rights reserved.
//

import UIKit

class CKRoomSettingsMembersCell: UITableViewCell {

    // MARK: - OUTLET
    
    @IBOutlet weak var imageMember: UIImageView!
    @IBOutlet weak var btnMembers: UIButton!
    
    // MARK: - VAR CLASS
    
    public class var identifier: String {
        return self.nibName
    }
    
    public class var nibName: String {
        return "CKRoomSettingsMembersCell"
    }

    // MARK: - OVERRIDE
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageMember.image = UIImage(named: "ic_room_members")
        self.accessoryType = .disclosureIndicator
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
