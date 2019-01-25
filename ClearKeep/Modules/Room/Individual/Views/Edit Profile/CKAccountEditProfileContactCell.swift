//
//  CKAccountEditProfileContactCell.swift
//  Riot
//
//  Created by Hiếu Nguyễn on 1/24/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

class CKAccountEditProfileContactCell: CKAccountEditProfileBaseCell {

    // MARK: - OUTLET
    
    @IBOutlet weak var contactTextField: UITextField!
    
    // MARK: - OVERRIDE
    
    /**
     edittingChangedHandler
     */
    internal var edittingChangedHandler: ((String?) -> Void)?
    
    // MARK: - OVERRIDE
    override func awakeFromNib() {
        super.awakeFromNib()
        self.contactTextField.addTarget(self, action: #selector(edittingChanged), for: .editingChanged)
    }
    
    // MARK: - ACTION
    
    @objc func edittingChanged(textField: UITextField) {
        edittingChangedHandler?(textField.text)
    }
}
