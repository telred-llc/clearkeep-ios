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
        self.backButton.image = UIImage(named: "ic_x_close")
        bindingTheme()
    }

    private func bindingTheme() {
        // Binding navigation bar color
        themeService.attrsStream.subscribe(onNext: { [weak self] (theme) in
            self?.defaultBarTintColor = themeService.attrs.primaryBgColor
            self?.barTitleColor = themeService.attrs.primaryTextColor
            self?.activityIndicator?.backgroundColor = themeService.attrs.overlayColor
        }).disposed(by: disposeBag)

        themeService.rx
            .bind({ $0.secondBgColor }, to: view.rx.backgroundColor)
            .disposed(by: disposeBag)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // fixbug: CK 309 - app crash when touch search button
        // -- release CKAttachmentsViewController before dismiss display
        self.destroy()
    }
}
