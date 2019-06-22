//
//  CKRecentItemFirstFavouriteCell.swift
//  Riot
//
//  Created by Sinbad Flyce on 2/15/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKRecentItemFirstFavouriteCell: CKBaseCell {
    
    // MARK: - OUTLE
    
    @IBOutlet weak var titleLabel: UILabel!
    
    // MARK: - PROPERTY
    
    // MARK: - OVERRIDE
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.titleLabel.theme.textColor = themeService.attrStream{ $0.secondTextColor }
    }    
}
