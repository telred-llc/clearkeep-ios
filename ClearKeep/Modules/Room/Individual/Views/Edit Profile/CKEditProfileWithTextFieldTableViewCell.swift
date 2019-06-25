//
//  CKEditAccountProfileTableViewCell.swift
//  Riot
//
//  Created by Pham Hoa on 2/1/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

class CKEditProfileWithTextFieldTableViewCell: CKAccountEditProfileBaseCell, UITextFieldDelegate {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var inputTextFiedContainerView: UIView!

    // MARK: - OVERRIDE
    
    /**
     edittingChangedHandler
     */
    internal var edittingChangedHandler: ((String?) -> Void)?
    
    // MARK: - OVERRIDE
    override func awakeFromNib() {
        super.awakeFromNib()
        inputTextField.delegate = self
        self.inputTextField.addTarget(self, action: #selector(edittingChanged), for: .editingChanged)
    }
    
    // MARK: - PUBLIC
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    
    // MARK: - ACTION
    
    @objc func edittingChanged(textField: UITextField) {
        edittingChangedHandler?(textField.text)
    }
}
