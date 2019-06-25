//
//  CKAccountProfileInfoCell.swift
//  Riot
//
//  Created by Hiếu Nguyễn on 1/23/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

class CKAccountProfileInfoCell: CKAccountProfileBaseCell {

    // MARK: - OUTLET
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        self.theme.backgroundColor = themeService.attrStream{ $0.secondBgColor }
        self.titleLabel.theme.textColor = themeService.attrStream{ $0.secondTextColor }
        self.contentLabel.theme.textColor = themeService.attrStream{ $0.primaryTextColor }
    }
}

