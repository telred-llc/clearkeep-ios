//
//  CKSettingDarkModeCell.swift
//  Riot
//
//  Created by Sinbad Flyce on 6/20/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

class CKSettingDarkModeCell: UITableViewCell {

    // MARK: - OUTLET
    @IBOutlet weak var switchView: UISwitch!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!

    // MARK: - OVERRIDE
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
