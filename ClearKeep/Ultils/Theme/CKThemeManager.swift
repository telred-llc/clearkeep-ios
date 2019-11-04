//
//  CKThemeManager.swift
//  Riot
//
//  Created by Pham Hoa on 6/20/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation
import RxTheme

// MARK - CK Theme Colors (depends on the selected theme light or dark).
protocol Theme {
    var primaryBgColor: UIColor { get }
    var secondBgColor: UIColor { get }
    var selectedBgColor: UIColor? { get }
    var tabbarTintColor: UIColor { get }

    var primaryTextColor: UIColor { get }
    var secondTextColor: UIColor { get } //subtitle, sending messages color.
    var placeholderTextColor: UIColor { get }
    var overlayColor: UIColor { get } // fading behind dialog modals. This color includes the transparency value.
    var separatorColor: UIColor { get } // tableview separator
    var unreadCellBgColor: UIColor { get }
    var cellPrimaryBgColor: UIColor { get }

    var searchBarBgColor: UIColor { get }
    var tblHeaderBgColor: UIColor { get }
    var navTitleTextAttributes: [NSAttributedString.Key: Any] { get }
    var navBarBgColor: UIColor { get }

    var statusBarStyle: UIStatusBarStyle { get }
    
    var newBackgroundColor: UIColor { get }
    
    var hintText: UIColor { get }
}

struct LightTheme: Theme {
    var navBarBgColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    var primaryBgColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    var secondBgColor = #colorLiteral(red: 0.9763854146, green: 0.9765253663, blue: 0.9763547778, alpha: 1)
    var selectedBgColor: UIColor? = nil
    var primaryTextColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    var placeholderTextColor = #colorLiteral(red: 0.7215686275, green: 0.7215686275, blue: 0.7215686275, alpha: 1)
    var overlayColor = UIColor.init(white: 0.3, alpha: 0.5)
    var separatorColor = UIColor.lightGray.withAlphaComponent(0.4)
    var secondTextColor = #colorLiteral(red: 0.370555222, green: 0.3705646992, blue: 0.3705595732, alpha: 1)
    var searchBarBgColor = #colorLiteral(red: 0.9411764706, green: 0.9411764706, blue: 0.9411764706, alpha: 1)
    var tblHeaderBgColor = #colorLiteral(red: 0.9411764706, green: 0.9411764706, blue: 0.9411764706, alpha: 1)
    var unreadCellBgColor = #colorLiteral(red: 0.7921568627, green: 0.9568627451, blue: 0.9843137255, alpha: 0.25)
    var cellPrimaryBgColor = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1)
    var tabbarTintColor = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1)
    var navTitleTextAttributes: [NSAttributedString.Key : Any] = [NSAttributedString.Key.foregroundColor: UIColor.black]
    var statusBarStyle = styleForStatusBar()
    var newBackgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    var hintText = #colorLiteral(red: 0.2666666667, green: 0.2666666667, blue: 0.2666666667, alpha: 1)

    static func styleForStatusBar() -> UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return UIStatusBarStyle.darkContent
        } else {
            return UIStatusBarStyle.default
        }
    }
}

struct DarkTheme: Theme {
    var navBarBgColor = #colorLiteral(red: 0.2509803922, green: 0.3254901961, blue: 0.4352941176, alpha: 1)
    var primaryBgColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    var secondBgColor = #colorLiteral(red: 0.2117647059, green: 0.2784313725, blue: 0.3647058824, alpha: 1)
    var selectedBgColor: UIColor? = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    var primaryTextColor = #colorLiteral(red: 0.8666666667, green: 0.8666666667, blue: 0.8666666667, alpha: 1)
    var secondTextColor = #colorLiteral(red: 0.7215686275, green: 0.7215686275, blue: 0.7215686275, alpha: 1)
    var placeholderTextColor = #colorLiteral(red: 0.7215686275, green: 0.7215686275, blue: 0.7215686275, alpha: 1)
    var overlayColor = UIColor.init(white: 0.3, alpha: 0.5)
    var separatorColor = UIColor.lightGray.withAlphaComponent(0.4)
    var searchBarBgColor = #colorLiteral(red: 0.137254902, green: 0.137254902, blue: 0.137254902, alpha: 1)
    var tblHeaderBgColor = #colorLiteral(red: 0.1882352941, green: 0.2431372549, blue: 0.3215686275, alpha: 1)
    var unreadCellBgColor = #colorLiteral(red: 0.9843137255, green: 0.9411764706, blue: 0.7921568627, alpha: 0.15)
    var cellPrimaryBgColor = #colorLiteral(red: 0.2509803922, green: 0.3254901961, blue: 0.4352941176, alpha: 1)
    var tabbarTintColor = #colorLiteral(red: 0, green: 0.8196078431, blue: 0.8941176471, alpha: 1)
    var navTitleTextAttributes: [NSAttributedString.Key : Any] = [NSAttributedString.Key.foregroundColor: UIColor.white]
    var statusBarStyle: UIStatusBarStyle = .lightContent
    var newBackgroundColor = #colorLiteral(red: 0.2509803922, green: 0.3254901961, blue: 0.4352941176, alpha: 1)
    var hintText = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
}

enum ThemeType: ThemeProvider {
    case light, dark
    var associatedObject: Theme {
        switch self {
        case .light:
            return LightTheme()
        case .dark:
            return DarkTheme()
        }
    }

    var typeName: String {
        switch self {
        case .light:
            ThemeService.shared.setupTheme(.light)
            return "light"
        case .dark:
            ThemeService.shared.setupTheme(.dark)
            return "dark"
        }
    }
}

let themeService = ThemeType.service(initial: .light)
