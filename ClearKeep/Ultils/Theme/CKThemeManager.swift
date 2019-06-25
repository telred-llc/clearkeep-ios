//
//  CKThemeManager.swift
//  Riot
//
//  Created by Pham Hoa on 6/20/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation
import RxTheme

let kDarkThemeTypeIdentifier = "DarkThemeTypeIdentifier"

// MARK - CK Theme Colors (depends on the selected theme light or dark).
protocol Theme {
    var primaryBgColor: UIColor { get }
    var secondBgColor: UIColor { get }

    var primaryTextColor: UIColor { get }
    var secondTextColor: UIColor { get }

    var searchBarBgColor: UIColor { get }
    var tblHeaderBgColor: UIColor { get }
    var navTitleTextAttributes: [NSAttributedString.Key: Any] { get }

    var statusBarStyle: UIStatusBarStyle { get }
}

struct LightTheme: Theme {
    var primaryBgColor = #colorLiteral(red: 0.9764705882, green: 0.9764705882, blue: 0.9764705882, alpha: 1)
    var secondBgColor = #colorLiteral(red: 0.9763854146, green: 0.9765253663, blue: 0.9763547778, alpha: 1)
    var primaryTextColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    var secondTextColor = #colorLiteral(red: 0.370555222, green: 0.3705646992, blue: 0.3705595732, alpha: 1)
    var searchBarBgColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    var tblHeaderBgColor = #colorLiteral(red: 0.7215686275, green: 0.7215686275, blue: 0.7215686275, alpha: 1)

    var navTitleTextAttributes: [NSAttributedString.Key : Any] = [NSAttributedString.Key.foregroundColor: UIColor.black]
    var statusBarStyle: UIStatusBarStyle = .default
}

struct DarkTheme: Theme {
    var primaryBgColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    var secondBgColor = #colorLiteral(red: 0.137254902, green: 0.137254902, blue: 0.137254902, alpha: 1)
    var primaryTextColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    var secondTextColor = #colorLiteral(red: 0.7215686275, green: 0.7215686275, blue: 0.7215686275, alpha: 1)
    var searchBarBgColor = #colorLiteral(red: 0.137254902, green: 0.137254902, blue: 0.137254902, alpha: 1)
    var tblHeaderBgColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)

    var navTitleTextAttributes: [NSAttributedString.Key : Any] = [NSAttributedString.Key.foregroundColor: UIColor.white]
    var statusBarStyle: UIStatusBarStyle = .lightContent
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
}

let themeService = ThemeType.service(initial: .light)
