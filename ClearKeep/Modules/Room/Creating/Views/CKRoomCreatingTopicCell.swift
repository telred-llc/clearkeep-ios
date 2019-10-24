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
    
    // MARK: - OVERRIDE
    override func awakeFromNib() {
        super.awakeFromNib()
        self.topicTextField.addTarget(self, action: #selector(edittingChanged), for: .editingChanged)
        self.topicTextField.addTarget(self, action: #selector(edittingBegin), for: .editingDidBegin)
        self.topicTextField.addTarget(self, action: #selector(edittingEnd), for: .editingDidEnd)
        self.topicTextField.rectangleBorder()
        self.topicTextField.borderColor = CKColor.Text.lightGray
        self.topicTextField.setLeftPaddingPoints(10)
        self.topicTextField.borderColor = CKColor.Text.lightGray
        self.lblHeader.textColor = CKColor.Text.lightGray
    }
    
    // MARK: - ACTION
    
    @objc func edittingChanged(textField: UITextField) {
        edittingChangedHandler?(textField.text)
    }
    
    @objc func edittingBegin(){
        self.topicTextField.borderColor = CKColor.Text.blueNavigation
        self.topicTextField.textColor = CKColor.Text.blueNavigation
        self.lblHeader.textColor = CKColor.Text.blueNavigation
        self.topicTextField.attributedPlaceholder = NSAttributedString(string: "Input text",
                                                                      attributes: [NSAttributedStringKey.foregroundColor: CKColor.Text.blueNavigation])
    }
    
    @objc func edittingEnd(){
        self.topicTextField.borderColor = CKColor.Text.lightGray
        self.topicTextField.textColor = CKColor.Text.lightGray
        self.lblHeader.textColor = CKColor.Text.lightGray
        self.topicTextField.attributedPlaceholder = NSAttributedString(string: "Input text",
                                                                      attributes: [NSAttributedStringKey.foregroundColor: CKColor.Text.lightGray])
    }
}
