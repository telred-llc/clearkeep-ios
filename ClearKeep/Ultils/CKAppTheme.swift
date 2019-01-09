//
//  CKAppTheme.swift
//  Riot
//
//  Created by Pham Hoa on 1/8/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

class CKAppTheme: NSObject {
    
    // MARK: - Fonts
    
    static func mainBlackAppFont(size: CGFloat) -> UIFont {
        return UIFont.init(name: "SFCompactDisplay-Black", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
    static func mainBoldAppFont(size: CGFloat) -> UIFont {
        return UIFont.init(name: "SFCompactDisplay-Bold", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
    static func mainHeavyAppFont(size: CGFloat) -> UIFont {
        return UIFont.init(name: "SFCompactDisplay-Heavy", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
    static func mainLightAppFont(size: CGFloat) -> UIFont {
        return UIFont.init(name: "SFCompactDisplay-Light", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
    static func mainMediumAppFont(size: CGFloat) -> UIFont {
        return UIFont.init(name: "SFCompactDisplay-Medium", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
    static func mainRegularAppFont(size: CGFloat) -> UIFont {
        return UIFont.init(name: "SFCompactDisplay-Regular", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
    static func mainSemiBoldAppFont(size: CGFloat) -> UIFont {
        return UIFont.init(name: "SFCompactDisplay-SemiBold", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
    static func mainThinAppFont(size: CGFloat) -> UIFont {
        return UIFont.init(name: "SFCompactDisplay-Thin", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
    static func mainUltraLightAppFont(size: CGFloat) -> UIFont {
        return UIFont.init(name: "SFCompactDisplay-UltraLight", size: size) ?? UIFont.systemFont(ofSize: size)
    }
}
