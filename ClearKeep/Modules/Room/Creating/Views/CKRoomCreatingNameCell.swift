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
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var lblHeader: UILabel!
    
    // MARK: - PROPERTY
    
    /**
     edittingChangedHandler
     */
    internal var edittingChangedHandler: ((String?) -> Void)?
    
    // MARK: - OVERRIDE
    override func awakeFromNib() {
        super.awakeFromNib()
        self.nameTextField.addTarget(self, action: #selector(edittingChanged), for: .editingChanged)
        self.nameTextField.addTarget(self, action: #selector(edittingBegin), for: .editingDidBegin)
        self.nameTextField.addTarget(self, action: #selector(edittingEnd), for: .editingDidEnd)
        self.nameTextField.rectangleBorder()
        self.nameTextField.setLeftPaddingPoints(10)
        self.nameTextField.borderColor = CKColor.Text.lightGray
        self.lblHeader.textColor = CKColor.Text.lightGray
        self.nameTextField.autocapitalizationType = .allCharacters
    }
    
    // MARK: - ACTION
    
    @objc func edittingChanged(textField: UITextField) {
        edittingChangedHandler?(textField.text?.uppercased())
    }
    
    @objc func edittingBegin(){
        self.nameTextField.borderColor = CKColor.Text.blueNavigation
        self.nameTextField.textColor = CKColor.Text.blueNavigation
        self.lblHeader.textColor = CKColor.Text.blueNavigation
        self.nameTextField.attributedPlaceholder = NSAttributedString(string: "Name",
                                                               attributes: [NSAttributedStringKey.foregroundColor: CKColor.Text.blueNavigation])
    }
    
    @objc func edittingEnd(){
        self.nameTextField.borderColor = CKColor.Text.lightGray
        self.nameTextField.textColor = CKColor.Text.lightGray
        self.lblHeader.textColor = CKColor.Text.lightGray
        self.nameTextField.attributedPlaceholder = NSAttributedString(string: "Name",
                                                                      attributes: [NSAttributedStringKey.foregroundColor: CKColor.Text.lightGray])
    }
}
