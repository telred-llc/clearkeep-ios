//
//  CKAlertSettingRoomCell.swift
//  Riot
//
//  Created by Vuong Le on 2/21/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

class CKAlertSettingRoomCell: UITableViewCell {
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var imgCell: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setUpCell(title: String, image: UIImage) {
        lblTitle.text = title
        imgCell.image = image
    }
}
