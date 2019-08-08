//
//  Topic.swift
//  FileXib
//
//  Created by Hiếu Nguyễn on 1/9/19.
//  Copyright © 2019 Hiếu Nguyễn. All rights reserved.
//

import UIKit

class CKRoomSettingsTopicCell: CKRoomSettingsBaseCell {
    
    // MARK: - OUTLET
    
    @IBOutlet weak var topicTextLabel: UILabel!
    @IBOutlet weak var topicLabel: UILabel!
    
    // MARK: - OVERIDDE
    
    override func awakeFromNib() {
        super.awakeFromNib()
        topicLabel.text = "Topic"
        topicTextLabel.text = "The channel topic appears in the channel header, and anyone in the channel can modify it."
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    // MARK: - PUBLIC
    
    public func enableEditTopic(_ isEnable: Bool) {
        if isEnable {
            self.isUserInteractionEnabled = true
            topicTextLabel.text = "Set a topic"
            topicTextLabel.textColor = CKColor.Misc.primaryGreenColor
        } else {
            self.isUserInteractionEnabled = false
            topicTextLabel.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        }
    }
}


