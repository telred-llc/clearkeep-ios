//
//  CKSettingButtonCell.swift
//  Riot
//
//  Created by Pham Hoa on 3/7/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

class CKSettingButtonCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.theme.backgroundColor = themeService.attrStream{ $0.primaryBgColor }
    }
}
