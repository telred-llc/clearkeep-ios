//
//  CKAccountProfileAvatarCell.swift
//  Riot
//
//  Created by Hiếu Nguyễn on 1/23/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

class CKAccountProfileAvatarCell: CKAccountProfileBaseCell {

    // MARK: - OUTLET
    
    @IBOutlet weak var avaImage: CKImageView!
    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var adminStatusView: UIImageView!
    @IBOutlet weak var adminLabel: UILabel!
    @IBOutlet weak var adminStackView: UIStackView!
    @IBOutlet weak var topAdminStackViewConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var trailingStatusViewConstraints: NSLayoutConstraint!
    @IBOutlet weak var bottomStatusViewConstraints: NSLayoutConstraint!
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var separatorView: UIView!
    
    // get current display name before edit
    var currentDisplayName: String = "" {
        didSet {
            nameTextField.text = currentDisplayName
            nameTextField.textColor = themeService.attrs.primaryTextColor
        }
    }
    
    var isShowDoneButton: Bool = false {
        didSet {
            nameTextField.textColor = isShowDoneButton ? themeService.attrs.navBarTintColor : themeService.attrs.primaryTextColor
            let image = isShowDoneButton ? #imageLiteral(resourceName: "done_button_profile").withRenderingMode(.alwaysTemplate) : #imageLiteral(resourceName: "edit_display_name_profile").withRenderingMode(.alwaysTemplate)
            doneButton.setImage(image, for: .normal)
            doneButton.theme.tintColor = themeService.attrStream { $0.primaryTextColor }
        }
    }
    
    var isCanEditDisplayName: Bool = false {
        didSet {
            avaImage.isUserInteractionEnabled = isCanEditDisplayName
            nameTextField.isUserInteractionEnabled = isCanEditDisplayName
            doneButton.isHidden = !isCanEditDisplayName
        }
    }
    
    var isAdminPower: Bool = false {
        didSet {
            adminStackView.isHidden = !isAdminPower
            topAdminStackViewConstraint.constant = isAdminPower ? 16 : -adminStackView.bounds.height
        }
    }
    
    var editAvatar: (() -> Void)?
    var editDisplayName: ((String) -> Void)?
    
    // MARK: - OVERRIDE
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        adminLabel.text = CKLocalization.string(byKey: "profile_admin")
        adminLabel.theme.textColor = themeService.attrStream{ $0.primaryTextColor }
        avaImage.defaultBackgroundColor = UIColor.clear
        avaImage.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin]
        avaImage.contentMode = UIView.ContentMode.scaleAspectFill
        statusView.layer.cornerRadius = self.statusView.bounds.width / 2
        statusView.layer.borderWidth = 1
        statusView.layer.borderColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        contentView.backgroundColor = .clear
        separatorView.theme.backgroundColor = themeService.attrStream { $0.navBarTintColor }
        isCanEditDisplayName = false
        avaImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleUpdateAvatar)))
        nameTextField.delegate = self
        
        isShowDoneButton = false
    }
    
    override func getMXKImageView() -> MXKImageView! {
        return self.avaImage
    }
    
    // MARK: - PUBLIC
    
    public func settingStatus(online: Bool)  {
        if online == true {
            statusView.backgroundColor = CKColor.Misc.onlineColor
        } else {
            statusView.backgroundColor = CKColor.Misc.offlineColor
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let cornerRadius = self.frame.width/4 //-- set width avatar = 1/2 width screen
        avaImage.cornerRadius = cornerRadius
        avaImage.layer.masksToBounds = true
        avaImage.borderWidth = 6
        avaImage.borderColor = #colorLiteral(red: 0.9098039216, green: 0.9529411765, blue: 0.9921568627, alpha: 1)
        
        trailingStatusViewConstraints.constant = -(cornerRadius/4 - self.statusView.bounds.width/3) - 3
        bottomStatusViewConstraints.constant = -(cornerRadius/4 - self.statusView.bounds.width/3)
    }
    
    @IBAction func doneAction(_ sender: Any) {
        if isShowDoneButton {
            self.endEditing(true)
            editDisplayName?((nameTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines))
        } else {
            nameTextField.becomeFirstResponder()
        }
    }
    
    @IBAction func editDislayNameAction(_ sender: Any) {
        updateDisplayNameIfNeeded()
        separatorView.isHidden = false
    }
}

// MARK: Handler Edit Display Name
extension CKAccountProfileAvatarCell: UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        separatorView.isHidden = false
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        endEditing(true)
        updateDisplayNameIfNeeded()
        return true
    }
    
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        let currentName = (nameTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        nameTextField.text = currentName
        separatorView.isHidden = true
    }
    
    private func updateDisplayNameIfNeeded() {
        let newDisplayName = (nameTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        isShowDoneButton = currentDisplayName != newDisplayName && !newDisplayName.isEmpty
    }
    
    override func becomeFirstResponder() -> Bool {
        
        if becomeFirstResponder() == false {
            self.endEditing(true)
            updateDisplayNameIfNeeded()
        }
        
        return super.becomeFirstResponder()
    }
    
}


extension CKAccountProfileAvatarCell {
    
    @objc
    private func handleUpdateAvatar() {
        editAvatar?()
    }
}
