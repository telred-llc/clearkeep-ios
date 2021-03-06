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
    var placeholderTextFieldColor: UIColor { get }
    var overlayColor: UIColor { get } // fading behind dialog modals. This color includes the transparency value.
    var separatorColor: UIColor { get } // tableview separator
    var unreadCellBgColor: UIColor { get }
    var cellPrimaryBgColor: UIColor { get }

    var searchBarBgColor: UIColor { get }
    var tblHeaderBgColor: UIColor { get }
    var navTitleTextAttributes: [NSAttributedString.Key: Any] { get }
    var navBarBgColor: UIColor { get }

    var statusBarStyle: UIStatusBarStyle { get }
    var hintText: UIColor { get }
    
    // textfiled
    var textFieldColor: UIColor { get }
    var textFieldEditingColor: UIColor { get }
    var textFieldBackground: UIColor { get }
    var textFieldEditingBackground: UIColor { get }
    
    var navBarTintColor: UIColor { get }
    var accessoryTblColor: UIColor { get }
    var pulseLayerColor: UIColor { get }

    // Button images
    var enableButtonBG: UIImage { get }
    var disableButtonBG: UIImage { get }
    var acceptButtonBg: UIImage { get }
    
    var checkBoxImage: UIImage { get }
    var joinRoomImage: UIImage { get }
    
}

struct LightTheme: Theme {
    var pulseLayerColor = #colorLiteral(red: 0.631372549, green: 0.7450980392, blue: 0.9725490196, alpha: 1)
    var navBarBgColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    var navBarTintColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
    var navTitleTextAttributes: [NSAttributedString.Key : Any] = [NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)]
    var primaryBgColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    var secondBgColor = #colorLiteral(red: 0.9763854146, green: 0.9765253663, blue: 0.9763547778, alpha: 1)
    var selectedBgColor: UIColor? = nil
    var primaryTextColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    var placeholderTextColor = #colorLiteral(red: 0.7215686275, green: 0.7215686275, blue: 0.7215686275, alpha: 1)
    var placeholderTextFieldColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
    var overlayColor = UIColor.init(white: 0.3, alpha: 0.5)
    var separatorColor = UIColor.lightGray.withAlphaComponent(0.4)
    var secondTextColor = #colorLiteral(red: 0.370555222, green: 0.3705646992, blue: 0.3705595732, alpha: 1)
    var searchBarBgColor = #colorLiteral(red: 0.9411764706, green: 0.9411764706, blue: 0.9411764706, alpha: 1)
    var tblHeaderBgColor = #colorLiteral(red: 0.9411764706, green: 0.9411764706, blue: 0.9411764706, alpha: 1)
    var unreadCellBgColor = #colorLiteral(red: 0.7921568627, green: 0.9568627451, blue: 0.9843137255, alpha: 0.25)
    var cellPrimaryBgColor = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1)
    var tabbarTintColor = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1)
    var statusBarStyle = styleForStatusBar()
    var hintText = #colorLiteral(red: 0.2666666667, green: 0.2666666667, blue: 0.2666666667, alpha: 1)
    var textFieldColor = #colorLiteral(red: 0.7450980392, green: 0.7450980392, blue: 0.7450980392, alpha: 1)
    var textFieldEditingColor = #colorLiteral(red: 0.3411764706, green: 0.5294117647, blue: 0.8901960784, alpha: 1)
    var textFieldBackground = #colorLiteral(red: 0.9607843137, green: 0.9607843137, blue: 0.9607843137, alpha: 1)
    var textFieldEditingBackground = UIColor.clear
    var enableButtonBG = #imageLiteral(resourceName: "btn_start_room_light")
    var disableButtonBG = #imageLiteral(resourceName: "bg_btn_not_valid")
    var accessoryTblColor = #colorLiteral(red: 0.4588235294, green: 0.4588235294, blue: 0.4588235294, alpha: 1)
    var acceptButtonBg = #imageLiteral(resourceName: "bg_button_start_chat")
    var checkBoxImage = #imageLiteral(resourceName: "ic_check_yes")
    var joinRoomImage = #imageLiteral(resourceName: "join_room_notification")
    static func styleForStatusBar() -> UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return UIStatusBarStyle.darkContent
        } else {
            return UIStatusBarStyle.default
        }
    }
}

struct DarkTheme: Theme {
    var navBarBgColor = #colorLiteral(red: 0.003921568627, green: 0, blue: 0.003921568627, alpha: 1)
    var navBarTintColor = #colorLiteral(red: 0, green: 0.7529411765, blue: 0.8470588235, alpha: 1)
    var navTitleTextAttributes: [NSAttributedString.Key : Any] = [NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0, green: 0.7529411765, blue: 0.8470588235, alpha: 1)]
    var primaryBgColor = #colorLiteral(red: 0.003921568627, green: 0.003921568627, blue: 0.003921568627, alpha: 1)
    var secondBgColor = #colorLiteral(red: 0.2117647059, green: 0.2784313725, blue: 0.3647058824, alpha: 1)
    var selectedBgColor: UIColor? = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    var primaryTextColor = #colorLiteral(red: 0.8666666667, green: 0.8666666667, blue: 0.8666666667, alpha: 1)
    var secondTextColor = #colorLiteral(red: 0.7215686275, green: 0.7215686275, blue: 0.7215686275, alpha: 1)
    var placeholderTextColor = #colorLiteral(red: 0.7215686275, green: 0.7215686275, blue: 0.7215686275, alpha: 1)
    var placeholderTextFieldColor = #colorLiteral(red: 0, green: 0.7529411765, blue: 0.8470588235, alpha: 1)
    var overlayColor = UIColor.init(white: 0.3, alpha: 0.5)
    var separatorColor = UIColor.lightGray.withAlphaComponent(0.4)
    var searchBarBgColor = #colorLiteral(red: 0.1254901961, green: 0.1254901961, blue: 0.137254902, alpha: 1)
    var tblHeaderBgColor = #colorLiteral(red: 0.1254901961, green: 0.1254901961, blue: 0.137254902, alpha: 1)
    var unreadCellBgColor = #colorLiteral(red: 0.9843137255, green: 0.9411764706, blue: 0.7921568627, alpha: 0.15)
    var cellPrimaryBgColor = #colorLiteral(red: 0.003921568627, green: 0.003921568627, blue: 0.003921568627, alpha: 1)
    var tabbarTintColor = #colorLiteral(red: 0, green: 0.8196078431, blue: 0.8941176471, alpha: 1)
    var pulseLayerColor = #colorLiteral(red: 0, green: 0.7529411765, blue: 0.8470588235, alpha: 1)
    var statusBarStyle: UIStatusBarStyle = .lightContent
    var hintText = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    var textFieldColor = #colorLiteral(red: 0.7450980392, green: 0.7450980392, blue: 0.7450980392, alpha: 1)
    var textFieldEditingColor = #colorLiteral(red: 0, green: 0.7529411765, blue: 0.8470588235, alpha: 1)
    var textFieldBackground = #colorLiteral(red: 0.1254901961, green: 0.1254901961, blue: 0.137254902, alpha: 0.5)
    var textFieldEditingBackground = #colorLiteral(red: 0.1254901961, green: 0.1254901961, blue: 0.137254902, alpha: 1)
    var enableButtonBG = #imageLiteral(resourceName: "btn_start_room_dark")
    var disableButtonBG = #imageLiteral(resourceName: "bg_btn_not_valid")
    var accessoryTblColor = #colorLiteral(red: 0.9607843137, green: 0.9607843137, blue: 0.9607843137, alpha: 1)
    var acceptButtonBg = #imageLiteral(resourceName: "btn_start_room_dark")
    var checkBoxImage = #imageLiteral(resourceName: "ic_check_yes_dark")
    var joinRoomImage = #imageLiteral(resourceName: "join_room_notification_dark")
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
