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
        signOutButton.setTitleColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), for: .normal)
        signOutButton.layer.cornerRadius = 3
        self.theme.backgroundColor = themeService.attrStream{ $0.primaryBgColor }
    }

    @IBAction func clickedOnSignOutButton(_ sender: Any) {
        signOutHandler?()
    }
    
}
