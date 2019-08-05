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

    var primaryTextColor: UIColor { get }
    var secondTextColor: UIColor { get } //subtitle, sending messages color.
    var placeholderTextColor: UIColor { get }
    var overlayColor: UIColor { get } // fading behind dialog modals. This color includes the transparency value.
    var separatorColor: UIColor { get } // tableview separator

    var searchBarBgColor: UIColor { get }
    var tblHeaderBgColor: UIColor { get }
    
    var navTitleTextAttributes: [NSAttributedString.Key: Any] { get }
    var statusBarStyle: UIStatusBarStyle { get }
    
    // From Riot
    var backgroundColor: UIColor { get }
    var selectedBackgroundColor: UIColor? { get }

    var baseColor: UIColor { get }
    
    var baseTextPrimaryColor: UIColor { get }
    var baseTextSecondaryColor: UIColor { get }
    
    var searchBackgroundColor: UIColor { get }
    var searchPlaceholderColor: UIColor { get }
    
    var headerBackgroundColor: UIColor { get }
    var headerBorderColor: UIColor { get }
    var headerTextPrimaryColor: UIColor { get }
    var headerTextSecondaryColor: UIColor { get }
    
    var textPrimaryColor: UIColor { get }
    var textSecondaryColor: UIColor { get }
    
    var tintColor: UIColor { get }
    var tintBackgroundColor: UIColor { get }
    
    var unreadRoomIndentColor: UIColor { get }
    
    var lineBreakColor: UIColor { get }
    
    var noticeColor: UIColor { get }
    var noticeSecondaryColor: UIColor { get }
    
    /// Color for errors or warnings
    var warningColor: UIColor { get }
    
}

struct LightTheme: Theme {
    var primaryBgColor              = #colorLiteral(red: 0.9764705882, green: 0.9764705882, blue: 0.9764705882, alpha: 1)
    var secondBgColor               = #colorLiteral(red: 0.9763854146, green: 0.9765253663, blue: 0.9763547778, alpha: 1)
    var selectedBgColor: UIColor?   = nil
    var primaryTextColor            = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    var secondTextColor             = #colorLiteral(red: 0.370555222, green: 0.3705646992, blue: 0.3705595732, alpha: 1)
    var placeholderTextColor        = #colorLiteral(red: 0.7215686275, green: 0.7215686275, blue: 0.7215686275, alpha: 1)
    var overlayColor                = UIColor.init(white: 0.3, alpha: 0.5)
    var separatorColor              = UIColor.lightGray.withAlphaComponent(0.4)
    var searchBarBgColor            = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    var tblHeaderBgColor            = #colorLiteral(red: 0.7215686275, green: 0.7215686275, blue: 0.7215686275, alpha: 1)

    var navTitleTextAttributes: [NSAttributedString.Key : Any]  = [NSAttributedString.Key.foregroundColor: UIColor.black]
    var statusBarStyle: UIStatusBarStyle                        = .default
    
    // From Riot
    var backgroundColor             = UIColor(rgb: 0xFFFFFF)
    var selectedBackgroundColor: UIColor?     = nil
    
    var baseColor                   = UIColor(rgb: 0x27303A)
    var baseTextPrimaryColor        = UIColor(rgb: 0xFFFFFF)
    var baseTextSecondaryColor      = UIColor(rgb: 0xFFFFFF)
    
    var searchBackgroundColor       = UIColor(rgb: 0xFFFFFF)
    var searchPlaceholderColor      = UIColor(rgb: 0x61708B)
    
    var headerBackgroundColor       = UIColor(rgb: 0xF3F8FD)
    var headerBorderColor           = UIColor(rgb: 0xE9EDF1)
    var headerTextPrimaryColor      = UIColor(rgb: 0x61708B)
    var headerTextSecondaryColor    = UIColor(rgb: 0xC8C8CD)
    
    var textPrimaryColor            = UIColor(rgb: 0x2E2F32)
    var textSecondaryColor          = UIColor(rgb: 0x9E9E9E)
    
    var tintColor                   = UIColor(rgb: 0x03B381)
    var tintBackgroundColor         = UIColor(rgb: 0xe9fff9)
    var unreadRoomIndentColor       = UIColor(rgb: 0x2E3648)
    var lineBreakColor              = UIColor(rgb: 0xEEEFEF)
    
    var noticeColor                 = UIColor(rgb: 0xFF4B55)
    var noticeSecondaryColor        = UIColor(rgb: 0x61708B)
    
    var warningColor                = UIColor(rgb: 0xFF4B55)
}

struct DarkTheme: Theme {
    var primaryBgColor              = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    var secondBgColor               = #colorLiteral(red: 0.137254902, green: 0.137254902, blue: 0.137254902, alpha: 1)
    var selectedBgColor: UIColor?   = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    var primaryTextColor            = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    var secondTextColor             = #colorLiteral(red: 0.7215686275, green: 0.7215686275, blue: 0.7215686275, alpha: 1)
    var placeholderTextColor        = #colorLiteral(red: 0.7215686275, green: 0.7215686275, blue: 0.7215686275, alpha: 1)
    var overlayColor                = UIColor.init(white: 0.3, alpha: 0.5)
    var separatorColor              = UIColor.lightGray.withAlphaComponent(0.4)
    var searchBarBgColor            = #colorLiteral(red: 0.137254902, green: 0.137254902, blue: 0.137254902, alpha: 1)
    var tblHeaderBgColor            = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)

    var navTitleTextAttributes: [NSAttributedString.Key : Any]  = [NSAttributedString.Key.foregroundColor: UIColor.white]
    var statusBarStyle: UIStatusBarStyle                        = .lightContent
    
    // From Riot
    var backgroundColor             = UIColor(rgb: 0x181B21)
    var selectedBackgroundColor: UIColor?    = UIColor.black
    
    var baseColor                   = UIColor(rgb: 0x15171B)
    var baseTextPrimaryColor        = UIColor(rgb: 0xEDF3FF)
    var baseTextSecondaryColor      = UIColor(rgb: 0xEDF3FF)
    
    var searchBackgroundColor       = UIColor(rgb: 0x181B21)
    var searchPlaceholderColor      = UIColor(rgb: 0x61708B)
    
    var headerBackgroundColor       = UIColor(rgb: 0x22262E)
    var headerBorderColor           = UIColor(rgb: 0x181B21)
    var headerTextPrimaryColor      = UIColor(rgb: 0xA1B2D1)
    var headerTextSecondaryColor    = UIColor(rgb: 0xC8C8CD)
    
    var textPrimaryColor            = UIColor(rgb: 0xEDF3FF)
    var textSecondaryColor          = UIColor(rgb: 0xA1B2D1)
    
    var tintColor                   = UIColor(rgb: 0x03B381)
    var tintBackgroundColor         = UIColor(rgb: 0x1F6954)
    var unreadRoomIndentColor       = UIColor(rgb: 0x2E3648)
    var lineBreakColor              = UIColor(rgb: 0x61708B)
    
    var noticeColor                 = UIColor(rgb: 0xFF4B55)
    var noticeSecondaryColor        = UIColor(rgb: 0x61708B)
    
    var warningColor                = UIColor(rgb: 0xFF4B55)
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
            return "light"
        case .dark:
            return "dark"
        }
    }
}

let themeService = ThemeType.service(initial: .light)
