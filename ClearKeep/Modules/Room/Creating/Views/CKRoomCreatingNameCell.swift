//
//  CKRoomCreatingNameCell.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/19/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKRoomCreatingNameCell: CKRoomCreatingBaseCell {
    
    // MARK: - OUTLET
    
    @IBOutlet weak var symbolLabel: UILabel!
    @IBOutlet weak var nameTextField: UITextField!
    
    // MARK: - PROPERTY
    
    /**
     edittingChangedHandler
     */
    internal var edittingChangedHandler: ((String?) -> Void)?
    
    // MARK: - OVERRIDE
    override func awakeFromNib() {
        super.awakeFromNib()
        self.nameTextField.addTarget(self, action: #selector(edittingChanged), for: .editingChanged)        
    }
    
    // MARK: - ACTION
    
    @objc func edittingChanged(textField: UITextField) {
        edittingChangedHandler?(textField.text)
    }
}
