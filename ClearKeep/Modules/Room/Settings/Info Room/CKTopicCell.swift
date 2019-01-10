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
}


