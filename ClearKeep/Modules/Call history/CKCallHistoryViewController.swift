//
//  CKCallHistoryViewController.swift
//  Riot
//
//  Created by klinh on 11/1/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

class CKCallHistoryViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.theme.backgroundColor = themeService.attrStream{$0.navBarBgColor}
    }
}
