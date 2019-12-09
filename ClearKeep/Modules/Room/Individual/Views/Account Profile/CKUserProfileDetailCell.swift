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
    
    
    func bindingData(icon: UIImage?, content: String?, placeholder: String?) {
        
        self.iconImageView.image = icon?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        self.iconImageView.tintColor = themeService.attrs.primaryTextColor
        
        let isContentExist = content != nil
        self.contentLabel.text = isContentExist ? content : placeholder
        self.contentLabel.textColor = isContentExist ? themeService.attrs.primaryTextColor : themeService.attrs.primaryTextColor.withAlphaComponent(0.3)
        self.contentLabel.font = isContentExist ? UIFont.systemFont(ofSize: 17) : UIFont.italicSystemFont(ofSize: 15)
        
        self.separatorView.backgroundColor = themeService.attrs.separatorColor
    }
    
}
