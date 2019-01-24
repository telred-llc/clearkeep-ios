//
//  CKRoomSettingsEditableCell.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/16/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKRoomSettingsEditableCell: CKRoomSettingsBaseCell {
    
    // MARK: - PROPERTY
    @IBOutlet weak var textField: UITextField!
    
    /**
     edittingChangedHandler
     */
    internal var edittingChangedHandler: ((String?) -> Void)?
    
    /**
     doneKeyboadHandler
     */
    internal var doneKeyboadHandler: (() -> Void)?
    
    // MARK: - OVERRIDE
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        textField.addTarget(self, action: #selector(edittingChanged), for: .editingChanged)
        textField.delegate = self
    }
    
    // MARK: - ACTION
    
    @objc func edittingChanged(textField: UITextField) {
        edittingChangedHandler?(textField.text)
    }
}

extension CKRoomSettingsEditableCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        doneKeyboadHandler?()
        return true
    }
}
