//
//  CKImageView.swift
//  Riot
//
//  Created by Hiếu Nguyễn on 1/28/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

class CKImageView: MXKImageView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    override func customizeRendering() {
        super.customizeRendering()
        
        backgroundColor = (defaultBackgroundColor != nil) ? defaultBackgroundColor : .black
        contentMode = .scaleAspectFill
        autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleTopMargin]
    }
}
