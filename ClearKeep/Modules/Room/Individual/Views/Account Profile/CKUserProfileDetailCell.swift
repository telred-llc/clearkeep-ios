//
//  CKUserProfileDetailCell.swift
//  Riot
//
//  Created by ReasonLeveing on 10/22/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

class CKUserProfileDetailCell: CKAccountProfileBaseCell {
    
    
    @IBOutlet weak private var iconImageView: UIImageView!
    @IBOutlet weak private var contentLabel: UILabel!
    @IBOutlet weak private var separatorView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        separatorView.backgroundColor = themeService.attrs.separatorColor
        contentLabel.textColor = themeService.attrs.primaryTextColor
    }
    
    
    func bindingData(icon: UIImage?, content: String?) {
        
        self.iconImageView.image = icon?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        self.iconImageView.tintColor = themeService.attrs.primaryTextColor
        
        self.contentLabel.text = content
        self.contentLabel.textColor = themeService.attrs.primaryTextColor
        self.separatorView.backgroundColor = themeService.attrs.separatorColor
    }
    
}
