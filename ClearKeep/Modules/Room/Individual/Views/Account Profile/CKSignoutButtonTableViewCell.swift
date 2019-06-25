//
//  CKSignoutButtonTableViewCell.swift
//  Riot
//
//  Created by Pham Hoa on 3/8/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

class CKSignoutButtonTableViewCell: CKBaseCell {
    
    @IBOutlet weak var signOutButton: UIButton!
    
    var signOutHandler: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        signOutButton.setTitleColor(kRiotColorRed, for: .normal)
        signOutButton.layer.cornerRadius = 3
        signOutButton.layer.borderWidth = 1
        signOutButton.layer.borderColor = CKColor.Misc.primaryGreenColor.cgColor

        self.theme.backgroundColor = themeService.attrStream{ $0.secondBgColor }
    }

    @IBAction func clickedOnSignOutButton(_ sender: Any) {
        signOutHandler?()
    }
    
}
