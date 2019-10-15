//
//  CKColor.swift
//  Riot
//
//  Created by Pham Hoa on 1/3/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

class CKColor {
    struct Text {
        static let primaryGreenColor: UIColor       = #colorLiteral(red: 0.3921568627, green: 0.8078431373, blue: 0.6235294118, alpha: 1)
        static let lightText: UIColor               = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        static let lightGray: UIColor               = #colorLiteral(red: 0.7215686275, green: 0.7215686275, blue: 0.7215686275, alpha: 1)
        static let lightBlueText: UIColor           = #colorLiteral(red: 0.1411764706, green: 0.5215686275, blue: 0.6705882353, alpha: 1)
        static let darkGray: UIColor                = #colorLiteral(red: 0.370555222, green: 0.3705646992, blue: 0.3705595732, alpha: 1)
        static let black: UIColor                   = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        static let white: UIColor                   = #colorLiteral(red: 0.9085063338, green: 0.9085063338, blue: 0.9085063338, alpha: 1)
        static let tint: UIColor                    = #colorLiteral(red: 0.01176470588, green: 0.7019607843, blue: 0.5058823529, alpha: 1)
        static let warning: UIColor                 = #colorLiteral(red: 1, green: 0.2941176471, blue: 0.3333333333, alpha: 1)
    }
    
    struct Background {
        static let primaryGreenColor: UIColor       = #colorLiteral(red: 0.3921568627, green: 0.8078431373, blue: 0.6235294118, alpha: 1)
        static let navigationBar: UIColor           = #colorLiteral(red: 0.9763854146, green: 0.9765253663, blue: 0.9763547778, alpha: 1)
        static let tableView: UIColor               = #colorLiteral(red: 0.9763854146, green: 0.9765253663, blue: 0.9763547778, alpha: 1)
        static let darkGray: UIColor                = #colorLiteral(red: 0.370555222, green: 0.3705646992, blue: 0.3705595732, alpha: 1)
        static let lightGray: UIColor               = #colorLiteral(red: 0.6666666865, green: 0.6666666865, blue: 0.6666666865, alpha: 1)
        static let blue: UIColor                    = #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1)
    }
    
    struct Misc {
        static let primaryGreenColor: UIColor       = #colorLiteral(red: 0.3921568627, green: 0.8078431373, blue: 0.6235294118, alpha: 1)
        static let borderColor: UIColor             = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        static let onlineColor: UIColor             = #colorLiteral(red: 0.2941176471, green: 0.8588235294, blue: 0.4235294118, alpha: 1)
        static let offlineColor: UIColor            = #colorLiteral(red: 0.6666666865, green: 0.6666666865, blue: 0.6666666865, alpha: 1)
        static let pulseCicleColor: UIColor         = #colorLiteral(red: 0.631372549, green: 0.7450980392, blue: 0.9725490196, alpha: 1)
    }
    
    static func applyStyle(onTabBar tabBar: UITabBar) {
        tabBar.tintColor = CKColor.Text.tint
        tabBar.barTintColor = themeService.attrs.secondBgColor
        tabBar.isTranslucent = false
    }
    
    static func applyStyle(onSearchBar searchBar: UISearchBar) {
        searchBar.barStyle = .default
        searchBar.tintColor = themeService.attrs.placeholderTextColor
        searchBar.barTintColor = themeService.attrs.secondBgColor
    }
    
    static func applyStyle(onTextField texField: UITextField) {
        texField.textColor = themeService.attrs.primaryTextColor
        texField.tintColor = CKColor.Text.tint
    }
    
    static func applyStyle(onButton button: UIButton) {
        // NOTE: Tint color does nothing by default on button type `UIButtonType.custom`
        button.tintColor = CKColor.Text.tint
    }
}
