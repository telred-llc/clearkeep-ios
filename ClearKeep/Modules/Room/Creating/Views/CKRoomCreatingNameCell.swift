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
    
    var triggerReturnHandler: (() -> Void)?
    
    // MARK: - OVERRIDE
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .clear
        self.selectionStyle = .none
        self.nameTextField.addTarget(self, action: #selector(edittingChanged), for: .editingChanged)
        self.nameTextField.rectangleBorder()
        self.nameTextField.setLeftPaddingPoints(10)
        self.nameTextField.autocapitalizationType = .allCharacters
        self.nameTextField.delegate = self
        self.nameTextField.clearButtonMode = .never
        self.focusEditingTextField(textField: nameTextField, isEditing: false)
    }
    
    // MARK: - ACTION
    
    @objc func edittingChanged(textField: UITextField) {
        
        let resultText = (textField.text ?? "").uppercased()
        nameTextField.text = resultText // force display name always uppercased
        edittingChangedHandler?(resultText.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    private func focusEditingTextField(textField: UITextField, isEditing: Bool = true) {
        
        let color = isEditing ? themeService.attrs.textFieldEditingColor : themeService.attrs.textFieldColor
        
        let background = isEditing ? themeService.attrs.textFieldEditingBackground : themeService.attrs.textFieldBackground
        textField.backgroundColor = background
        
        lblHeader.textColor = color
        
        textField.borderColor = color
        textField.textColor = themeService.attrs.textFieldEditingColor
        textField.attributedPlaceholder = NSAttributedString(string: CKLocalization.string(byKey: "topic_name_room_placeholder"), attributes: [NSAttributedStringKey.foregroundColor: color.withAlphaComponent(0.7)])
//        textField.setClearButtonColorTo(color: themeService.attrs.secondTextColor)
    }
}

extension CKRoomCreatingNameCell: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        focusEditingTextField(textField: nameTextField, isEditing: true)
    }
    
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        focusEditingTextField(textField: nameTextField, isEditing: false)
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        triggerReturnHandler?()
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return true
    }
    
}
