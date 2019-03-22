//
//  CKAssignAdminButtonTableViewCell.swift
//  Riot
//
//  Created by Developer Super on 3/21/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

class CKAssignAdminButtonTableViewCell: CKBaseCell {
    
    @IBOutlet weak var assignAdminButton: UIButton!
    
    var assignAdminHandler: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    @IBAction func tapAssignAdminButton(_ sender: Any) {
        assignAdminHandler?()
    }
    
}
