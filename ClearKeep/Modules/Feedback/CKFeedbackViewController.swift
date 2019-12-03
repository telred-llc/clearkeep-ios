//
//  FeedbackViewController.swift
//  Riot
//
//  Created by ReasonLeveing on 11/29/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

class CKFeedbackViewController: MXKViewController {
    
    @IBOutlet weak var ratingControl: RatingControl! {
        didSet {
            ratingControl.rating = 0
        }
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var separatorLineView: UIView!
    @IBOutlet weak var feedbackLabel: UILabel!
    @IBOutlet weak var feedbackTextView: UITextView!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var clearAllButton: UIButton!
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindingTheme()
    }

    private func bindingTheme() {
        // Binding navigation bar color
        themeService.attrsStream.subscribe(onNext: { [weak self] (theme) in
            self?.defaultBarTintColor = themeService.attrs.navBarBgColor
            self?.barTitleColor = themeService.attrs.primaryTextColor
            self?.submitButton.setBackgroundImage(themeService.attrs.enableButtonBG, for: .normal)
        }).disposed(by: disposeBag)

        themeService.rx
            .bind({ $0.primaryBgColor }, to: view.rx.backgroundColor)
            .disposed(by: disposeBag)
        
        separatorLineView.theme.backgroundColor = themeService.attrStream { $0.accessoryTblColor }
        titleLabel.theme.textColor = themeService.attrStream { $0.navBarTintColor }
        feedbackLabel.theme.textColor = themeService.attrStream { $0.primaryTextColor }
        feedbackTextView.theme.textColor = themeService.attrStream { $0.primaryTextColor }
        feedbackTextView.theme.backgroundColor = themeService.attrStream { $0.tblHeaderBgColor }
        
        submitButton.setTitleColor(.white, for: .normal)
        clearAllButton.theme.titleColor(from: themeService.attrStream { $0.secondTextColor }, for: .normal)
    }
}
