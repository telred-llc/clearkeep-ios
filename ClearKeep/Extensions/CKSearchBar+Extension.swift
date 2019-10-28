//
//  CKSearchBar+Extension.swift
//  Riot
//
//  Created by Pham Hoa on 6/22/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

extension UISearchBar {
    @objc
    func setTextFieldColor(color: UIColor) {
        if let textField = getViewElement(type: UITextField.self) {
            switch searchBarStyle {
            case .minimal:
                textField.layer.backgroundColor = color.cgColor
                textField.layer.cornerRadius = 6
            case .prominent, .default:
                textField.backgroundColor = color
            }
        }
    }

    @objc
    func setTextFieldTextColor(color: UIColor) {
        if let textField = getViewElement(type: UITextField.self) {
            textField.textColor = color
        }
    }
}

