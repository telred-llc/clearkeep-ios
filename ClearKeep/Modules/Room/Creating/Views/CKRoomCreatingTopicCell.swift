//
//  CKRoomCreatingTopicCell.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/19/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKRoomCreatingTopicCell: CKRoomCreatingBaseCell {
    
    // MARK: - OUTLET
    
    @IBOutlet weak var topicTextField: UITextField!
    @IBOutlet weak var lblHeader: UILabel!
    
    // MARK: - OVERRIDE
    
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
        self.topicTextField.addTarget(self, action: #selector(edittingChanged), for: .editingChanged)
        self.topicTextField.rectangleBorder()
        self.topicTextField.setLeftPaddingPoints(10)
        self.topicTextField.delegate = self
        self.topicTextField.clearButtonMode = .never
        self.focusEditingTextField(textField: topicTextField, isEditing: false)
    }
    
    // MARK: - ACTION
    
    @objc func edittingChanged(textField: UITextField) {
        let resultText = (textField.text ?? "")
        edittingChangedHandler?(resultText.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    private func focusEditingTextField(textField: UITextField, isEditing: Bool = true) {
        
        let color = isEditing ? themeService.attrs.textFieldEditingColor : themeService.attrs.textFieldColor
        
        let background = isEditing ? themeService.attrs.textFieldEditingBackground : themeService.attrs.textFieldBackground
        textField.backgroundColor = background
        
        lblHeader.textColor = color
        
        textField.borderColor = color
        textField.textColor = themeService.attrs.textFieldEditingColor
        
        textField.attributedPlaceholder = NSAttributedString(string: CKLocalization.string(byKey: "display_name_room_placeholder"), attributes: [NSAttributedStringKey.foregroundColor: color.withAlphaComponent(0.7)])
    }

    
}

extension CKRoomCreatingTopicCell: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        focusEditingTextField(textField: topicTextField, isEditing: true)
    }
    
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        focusEditingTextField(textField: topicTextField, isEditing: false)
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        triggerReturnHandler?()
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return true
    }
}
