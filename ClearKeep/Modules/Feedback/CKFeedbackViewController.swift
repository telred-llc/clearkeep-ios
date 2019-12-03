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
            ratingControl.delegate = self
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
    
    var feedbackModel: CKFeedback.Request = CKFeedback.Request(stars: 0, content: "")
    
    var isEnableSubmit: Bool = false {
        didSet {
            let backgroundImage = isEnableSubmit ? themeService.attrs.enableButtonBG : themeService.attrs.disableButtonBG
            submitButton.isEnabled = isEnableSubmit
            submitButton.setBackgroundImage(backgroundImage, for: .normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isEnableSubmit = false
        addCustomBackButton()
        setupView()
        bindingTheme()
    }

    private func bindingTheme() {
        // Binding navigation bar color
        themeService.attrsStream.subscribe(onNext: { [weak self] (theme) in
            self?.defaultBarTintColor = themeService.attrs.navBarBgColor
            self?.barTitleColor = themeService.attrs.navBarTintColor
            let backgroundImage = (self?.isEnableSubmit ?? false) ? theme.enableButtonBG : theme.disableButtonBG
            self?.submitButton.setBackgroundImage(backgroundImage, for: .normal)
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
    
    private func setupView() {
        title = CKLocalization.string(byKey: "feedback_setting")
        
        titleLabel.text = CKLocalization.string(byKey: "feedback_setting_enjoy_clearkeep")
        feedbackLabel.text = CKLocalization.string(byKey: "feedback_setting_title")
        submitButton.setTitle(CKLocalization.string(byKey: "feedback_setting_submit").uppercased(), for: .normal)
        clearAllButton.setTitle(CKLocalization.string(byKey: "feedback_setting_clear_all"), for: .normal)
    }
    
    
    @IBAction func submitAction(_ sender: Any) {
        
        let contentFeedback = feedbackTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        feedbackModel.content = contentFeedback
        
        showSpinner()
        CKAppManager.shared.apiClient.requestFeedback(feedbackModel).done { (response) in
            self.removeSpinner()
            self.showAlert(CKLocalization.string(byKey: "feedback_setting_submit_success")) {
                self.resetAllData()
            }
        }.catch { (error) in
            self.removeSpinner()
            self.showAlert(error.localizedDescription)
        }
        
    }
    
    @IBAction func clearAllAction(_ sender: Any) {
        resetAllData()
    }
    
    
    private func resetAllData() {
        feedbackTextView.text = ""
        ratingControl.rating = 0
        isEnableSubmit = false
        
        feedbackModel.content = ""
        feedbackModel.stars = 0
    }
    
}

extension CKFeedbackViewController: RatingControlDelegate {
    
    func didSelectStar(_ number: Int) {
        feedbackModel.stars = number
        isEnableSubmit = number > 0
    }
}
