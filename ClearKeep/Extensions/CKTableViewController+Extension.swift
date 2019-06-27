//
//  CKTableViewController+Extension.swift
//  Riot
//
//  Created by Pham Hoa on 6/27/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

extension UINavigationController {
    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return themeService.attrs.statusBarStyle
    }
}
