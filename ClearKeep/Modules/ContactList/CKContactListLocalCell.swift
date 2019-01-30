//
//  CKContactListLocalCell.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/28/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKContactListLocalCell: CKContactListBaseCell {
    
    // MARK: - OUTLET
    
    @IBOutlet weak var photoView: UIImageView!
    @IBOutlet weak var displayNameLabel: UILabel!
    
    // MARK: - OVERRIDE
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
