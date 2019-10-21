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
    
    // MARK: - OVERRIDE
    
    /**
     edittingChangedHandler
     */
    internal var edittingChangedHandler: ((String?) -> Void)?
    
    // MARK: - OVERRIDE
    override func awakeFromNib() {
        super.awakeFromNib()
        self.topicTextField.addTarget(self, action: #selector(edittingChanged), for: .editingChanged)
        self.topicTextField.rectangleBorder()
        self.topicTextField.borderColor = CKColor.Text.lightGray
        self.topicTextField.setLeftPaddingPoints(10)
    }
    
    // MARK: - ACTION
    
    @objc func edittingChanged(textField: UITextField) {
        edittingChangedHandler?(textField.text)
    }
}
