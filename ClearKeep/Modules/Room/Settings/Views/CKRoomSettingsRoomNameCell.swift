//
//  RoomName.swift
//  FileXib
//
//  Created by Hiếu Nguyễn on 1/9/19.
//  Copyright © 2019 Hiếu Nguyễn. All rights reserved.
//

import UIKit

class CKRoomSettingsRoomNameCell: CKRoomSettingsBaseCell {
    
    // MARK: - OUTLET
    
    @IBOutlet weak var roomnameLabel: UILabel!
    
    // MARK: - OVERRIDE
    
    override func awakeFromNib() {
        super.awakeFromNib()
        roomnameLabel.text = "#room-name"                
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
}
