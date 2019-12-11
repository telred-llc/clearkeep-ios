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
        
        self.navigationBar.frame.origin.y = self.safeArea.top
        setupNavigationBar(color: .black)
    }

    private func bindingTheme() {
        // Binding navigation bar color
        themeService.attrsStream.subscribe(onNext: { [weak self] (theme) in
            self?.defaultBarTintColor = themeService.attrs.primaryBgColor
            self?.barTitleColor = themeService.attrs.primaryTextColor
            self?.activityIndicator?.backgroundColor = themeService.attrs.overlayColor
            self?.view.backgroundColor = themeService.attrs.primaryBgColor
        }).disposed(by: disposeBag)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // fixbug: CK 309 - app crash when touch search button
        // -- release CKAttachmentsViewController before dismiss display
        self.destroy()
    }
}

extension CKAttachmentsViewController {
    
    func setupNavigationBar(color: UIColor) {
        var alphaValue: CGFloat = 1.0
        color.getRed(nil, green: nil, blue: nil, alpha: &alphaValue)
        
        self.navigationBar.setBackgroundImage(UIImage.init(color: color), for: .default)
        self.navigationBar.isTranslucent = alphaValue < 1
        
        self.navigationBar.shadowImage = UIImage()
    }
}
