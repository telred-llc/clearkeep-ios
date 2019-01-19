//
//  FilesCell.swift
//  FileXib
//
//  Created by Hiếu Nguyễn on 1/9/19.
//  Copyright © 2019 Hiếu Nguyễn. All rights reserved.
//

import UIKit

class CKRoomSettingsFilesCell: CKRoomSettingsBaseCell {

    // MARK: - OUTLET
    
    @IBOutlet weak var btnFile: UIButton!
    @IBOutlet weak var imageFiles: UIImageView!
    
    // MARK: - OVERRIDE
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageFiles.image = UIImage(named: "ic_room_file")
        self.accessoryType = .disclosureIndicator
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
