//
//  Topic.swift
//  FileXib
//
//  Created by Hiếu Nguyễn on 1/9/19.
//  Copyright © 2019 Hiếu Nguyễn. All rights reserved.
//

import UIKit

class CKTopicCell: UITableViewCell {
    
    @IBOutlet weak var topicTextLabel: UILabel!
    @IBOutlet weak var topicLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        topicLabel.text = "Topic"
        topicTextLabel.text = "A SARE Topic Room is an organized collection of mostly SARE-based"
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func enableEditTopic(_ isEnable: Bool) {
        if isEnable {
            self.isUserInteractionEnabled = true
            topicTextLabel.text = "Set a topic"
            topicTextLabel.textColor = #colorLiteral(red: 0.1411764706, green: 0.5215686275, blue: 0.6705882353, alpha: 1)
        } else {
            self.isUserInteractionEnabled = false
            topicTextLabel.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        }
    }
}


