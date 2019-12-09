//
//  FeedbackViewController.swift
//  Riot
//
//  Created by ReasonLeveing on 11/29/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

@objc class CKFeedbackViewController: MXKViewController {
    
    @IBOutlet weak var ratingControl: RatingControl! {
        didSet {
            ratingControl.delegate = self
            ratingControl.rating = 0
        }
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var separatorLineView: UIView!
    @IBOutlet weak var feedbackLabel: UILabel!
    @IBOutlet weak var placeholderFeedbackLabel: UILabel!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var clearAllButton: UIButton!
    @IBOutlet weak var feedbackTextView: UITextView! {
        didSet {
            feedbackTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
            feedbackTextView.delegate = self
        }
    }
    
    var feedbackModel: CKFeedback.Request = CKFeedback.Request(stars: 0, content: "") {
        didSet {
            placeholderFeedbackLabel.isHidden = !(feedbackTextView.text ?? "").isEmpty
        }
    }
    
    let disposeBag = DisposeBag()
    
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
            self?.changeNavigationBar(color: .clear)
        }).disposed(by: disposeBag)

        themeService.rx
            .bind({ $0.primaryBgColor }, to: view.rx.backgroundColor)
            .disposed(by: disposeBag)
        
        separatorLineView.theme.backgroundColor = themeService.attrStream { $0.accessoryTblColor }
        titleLabel.theme.textColor = themeService.attrStream { $0.navBarTintColor }
        feedbackLabel.theme.textColor = themeService.attrStream { $0.primaryTextColor }
        feedbackTextView.theme.textColor = themeService.attrStream { $0.primaryTextColor }
        feedbackTextView.theme.backgroundColor = themeService.attrStream { $0.tblHeaderBgColor }
        feedbackTextView.theme.tintColor = themeService.attrStream { $0.placeholderTextFieldColor }
        placeholderFeedbackLabel.theme.textColor = themeService.attrStream { $0.placeholderTextFieldColor.withAlphaComponent(0.6) }
        
        submitButton.setTitleColor(.white, for: .normal)
        clearAllButton.theme.titleColor(from: themeService.attrStream { $0.secondTextColor }, for: .normal)
    }
    
    private func setupView() {
        title = CKLocalization.string(byKey: "feedback_setting")
        
        titleLabel.text = CKLocalization.string(byKey: "feedback_setting_enjoy_clearkeep")
        feedbackLabel.text = CKLocalization.string(byKey: "feedback_setting_title")
        submitButton.setTitle(CKLocalization.string(byKey: "feedback_setting_submit").uppercased(), for: .normal)
        clearAllButton.setTitle(CKLocalization.string(byKey: "feedback_setting_clear_all"), for: .normal)
        
        placeholderFeedbackLabel.isHidden = !(feedbackTextView.text ?? "").isEmpty
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
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

extension CKFeedbackViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        feedbackModel.content = textView.text
    }
}
