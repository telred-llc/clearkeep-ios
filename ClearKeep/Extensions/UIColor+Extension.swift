//
//  UIColor+Extension.swift
//  Riot
//
//  Created by Vũ Hai on 7/12/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

@objc extension UIColor {
    convenience init(rgb: UInt) {
        self.init(
            red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgb & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}
