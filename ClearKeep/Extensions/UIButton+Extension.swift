//
//  UIButton+Extension.swift
//  Riot
//
//  Created by Vũ Hai on 7/12/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

extension UIButton {
    
    /// Enable multiple lines for button title.
    ///
    /// - Parameter textAlignment: Title text alignement. Default `NSTextAlignment.center`.
    func vc_enableMultiLinesTitle(textAlignment: NSTextAlignment = .center) {
        guard let titleLabel = self.titleLabel else {
            return
        }
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = textAlignment
    }
}
