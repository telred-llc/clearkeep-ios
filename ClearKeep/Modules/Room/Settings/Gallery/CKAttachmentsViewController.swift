//
//  CKAttachmentsViewController.swift
//  Riot
//
//  Created by Developer Super on 3/26/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

class CKAttachmentsViewController: MXKAttachmentsViewController {

    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.backButton.image = #imageLiteral(resourceName: "cancel").withRenderingMode(.alwaysTemplate)
        self.backButton.theme.tintColor = themeService.attrStream{ $0.navBarTintColor }
        bindingTheme()
    }

    private func bindingTheme() {
        // Binding navigation bar color
        themeService.attrsStream.subscribe(onNext: { [weak self] (theme) in
            self?.defaultBarTintColor = themeService.attrs.primaryBgColor
            self?.barTitleColor = themeService.attrs.primaryTextColor
            self?.activityIndicator?.backgroundColor = themeService.attrs.overlayColor
            self?.view.backgroundColor = themeService.attrs.secondBgColor
        }).disposed(by: disposeBag)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // fixbug: CK 309 - app crash when touch search button
        // -- release CKAttachmentsViewController before dismiss display
        self.destroy()
    }
}
