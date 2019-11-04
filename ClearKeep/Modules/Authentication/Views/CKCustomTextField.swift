//
//  CKCustomTextField.swift
//  Riot
//
//  Created by ReasonLeveing on 10/30/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

class CKCustomTextField: UIView {
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet weak var contentTextField: UITextField!
    
    var placeholder: String = "Enter input" {
        didSet {
            let color = isFocusTextField ? themeService.attrs.textFieldEditingColor : themeService.attrs.textFieldColor
            self.contentTextField.attributedPlaceholder = NSAttributedString(string: self.placeholder, attributes: [NSAttributedStringKey.foregroundColor: color.withAlphaComponent(0.5)])
        }
    }
    
    var configReturnTypeKeyboard: UIReturnKeyType = .default {
        didSet {
            contentTextField.returnKeyType = configReturnTypeKeyboard
        }
    }
    
    var triggerReturn: ((UITextField) -> Void)?
    
    var edittingChangedHandler: ((String?) -> Void)?
    
    var isFocusTextField: Bool = false {
        didSet {
            let color = isFocusTextField ? themeService.attrs.textFieldEditingColor : themeService.attrs.textFieldColor
            self.titleLabel.textColor = color
            self.contentTextField.borderColor = color
            self.contentTextField.borderColor = color
            self.contentTextField.textColor = color
            self.contentTextField.backgroundColor = themeService.attrs.textFieldBackground
            
            self.contentTextField.attributedPlaceholder = NSAttributedString(string: self.placeholder, attributes: [NSAttributedStringKey.foregroundColor: color.withAlphaComponent(0.5)])
        }
    }
    
    
    
    private func commonInit() {
        guard let subview = UINib(nibName: "CKCustomTextField", bundle: nil)
            .instantiate(withOwner: self, options: nil).first as? UIView else { return }
        
        subview.frame = bounds
        subview.frame = bounds
        subview.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        addSubview(subview)
        backgroundColor = .clear
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentTextField.delegate = self
        contentTextField.addTarget(self, action: #selector(edittingChanged), for: .editingChanged)
        self.contentTextField.setLeftPaddingPoints(10)
        self.contentTextField.rectangleBorder(6)
        
        isFocusTextField = false
        
        configReturnTypeKeyboard = .default
    }
    
    
    func bindingData(title: String, isPassword: Bool = false) {
        contentTextField.isSecureTextEntry = isPassword
        titleLabel.text = title
    }
    
}


extension CKCustomTextField: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        isFocusTextField = true
    }
    
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        isFocusTextField = false
        
        if !(self.contentTextField.text ?? "").isEmpty {
            self.contentTextField.textColor = themeService.attrs.textFieldEditingColor
        }
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        triggerReturn?(textField)
        return true
    }
    
    @objc
    private func edittingChanged(textField: UITextField) {
        edittingChangedHandler?(textField.text)
    }
    
}
