//
//  CKEditRoomSettingsCell.swift
//  Riot
//
//  Created by ReasonLeveing on 11/4/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

class CKEditRoomSettingsCell: CKBaseCell {
    
    
    @IBOutlet weak private var avatarRoomView: MXKImageView!
    @IBOutlet weak private var infoCreateRoomLabel: UILabel!
    @IBOutlet weak private var titleRoomTextField: UITextField!
    @IBOutlet weak private var topicRoomTextField: UITextField!
    @IBOutlet weak private var saveButton: UIButton!
    @IBOutlet weak private var topSaveButtonConstraint: NSLayoutConstraint!
    @IBOutlet weak private var maskCameraView: UIView!
    
    private var currentRoomData = (displayRoom: "", topicRoom: "")
    
    private var newEditRoomData = (displayRoom: "", topicRoom: "") {
        didSet {
            isEnableSaveButton = currentRoomData != newEditRoomData
        }
    }
    
    var editAvatarHandler: (() -> Void)?
    
    var onSaveHandler: ((String, String) -> Void)?
    
    var isEnableSaveButton: Bool = false {
        didSet {
            saveButton.isEnabled = isEnableSaveButton
            let image: UIImage = isEnableSaveButton ? themeService.attrs.enableButtonBG : themeService.attrs.disableButtonBG
            saveButton.setBackgroundImage(image, for: .normal)
        }
    }
    
    var isAdminEdit: Bool = false {
        didSet {
            if isAdminEdit {
                titleRoomTextField.setRightIconEdit(icon: #imageLiteral(resourceName: "edit_display_name_profile"))
                topicRoomTextField.setRightIconEdit(icon: #imageLiteral(resourceName: "edit_display_name_profile"))
            }
            
            titleRoomTextField.isEnabled = isAdminEdit
            topicRoomTextField.isEnabled = isAdminEdit
            maskCameraView.isUserInteractionEnabled = isAdminEdit
            
            topSaveButtonConstraint.constant = isAdminEdit ? 30 : -saveButton.frame.height
            saveButton.isHidden = !isAdminEdit
            
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        isAdminEdit = false
        isEnableSaveButton = false
        
        avatarRoomView.backgroundColor = .clear
        titleRoomTextField.setLeftPaddingPoints(10)
        titleRoomTextField.rectangleBorder(4)
        titleRoomTextField.borderColor = #colorLiteral(red: 0.7450980392, green: 0.7450980392, blue: 0.7450980392, alpha: 1)
        
        topicRoomTextField.setLeftPaddingPoints(10)
        topicRoomTextField.rectangleBorder(4)
        topicRoomTextField.borderColor = #colorLiteral(red: 0.7450980392, green: 0.7450980392, blue: 0.7450980392, alpha: 1)
        
        titleRoomTextField.delegate = self
        titleRoomTextField.addTarget(self, action: #selector(edittingChanged), for: .editingChanged)
        titleRoomTextField.textColor = themeService.attrs.textFieldEditingColor
        titleRoomTextField.backgroundColor = themeService.attrs.textFieldBackground
        
        topicRoomTextField.delegate = self
        topicRoomTextField.addTarget(self, action: #selector(edittingChanged), for: .editingChanged)
        topicRoomTextField.textColor = themeService.attrs.textFieldEditingColor
        topicRoomTextField.backgroundColor = themeService.attrs.textFieldBackground
        
        maskCameraView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTakePhoto)))
        
        self.theme.backgroundColor = themeService.attrStream{ $0.primaryBgColor }
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        avatarRoomView.cornerRadius = self.frame.width / 6
        avatarRoomView.clipsToBounds = true
        
        maskCameraView.cornerRadius = self.frame.width / 6
        maskCameraView.clipsToBounds = true
        maskCameraView.borderColor = #colorLiteral(red: 0.9098039216, green: 0.9529411765, blue: 0.9921568627, alpha: 1)
        maskCameraView.borderWidth = 6
        
    }
    
    
    func bindingData(mxRoom: MXRoom, mxRoomState: MXRoomState?) {
        
        infoCreateRoomLabel.attributedText = topicCreatAttributeBy(mxRoom: mxRoom, mxRoomState: mxRoomState)
        
        let previewImage = AvatarGenerator.generateAvatar(forText: mxRoom.summary.displayname ?? "A")

        avatarRoomView?.setImageURI(mxRoom.summary.avatar,
                                   withType: "image/jpeg",
                                   andImageOrientation: .up,
                                   toFitViewSize: CGSize(width: self.frame.width / 6, height: self.frame.width / 6),
                                   with: MXThumbnailingMethodCrop,
                                   previewImage: previewImage,
                                   mediaManager: mxRoom.summary.mxSession.mediaManager)
        
        let displayRoom = (mxRoom.summary.displayname ?? "").uppercased()
        titleRoomTextField.text = displayRoom
        currentRoomData.displayRoom = displayRoom
        
        
        let topicName = (mxRoom.summary.topic ?? "").isEmpty ? displayRoom : (mxRoom.summary.topic ?? "")
        topicRoomTextField.text = topicName
        currentRoomData.topicRoom = topicName
        
        newEditRoomData = currentRoomData // set data
    }
    
    @IBAction func saveAction(_ sender: Any) {
        onSaveHandler?(newEditRoomData.displayRoom, newEditRoomData.topicRoom)
    }
}

extension CKEditRoomSettingsCell {
    
    @objc func edittingChanged(textField: UITextField) {
        
        if textField == titleRoomTextField {
            newEditRoomData.displayRoom = (titleRoomTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            newEditRoomData.topicRoom = (topicRoomTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        if textField == topicRoomTextField { return }
        
        let editText = (textField.text ?? "").uppercased()
        textField.text = editText
    }
    
    
    @objc func handleTakePhoto() {
//        isEnableSaveButton = true
        editAvatarHandler?()
    }
}

extension CKEditRoomSettingsCell {
    
    private func topicCreatAttributeBy(mxRoom: MXRoom, mxRoomState: MXRoomState?) -> NSAttributedString {
        
        let createrID = mxRoomState?.creator ?? ""
        
        let createrName = mxRoom.mxSession.getOrCreateUser(createrID)?.displayname ?? "@unknown"
        
        var dateString = "unknown"
        
        let eventFormat = EventFormatter(matrixSession: mxRoom.mxSession)
        
        if let date = mxRoomState?.createdDate {
            dateString = eventFormat?.dateString(from: date, withTime: true) ?? "unknown"
        }
        
        // -- attribute Color
        let normalText = [NSAttributedStringKey.foregroundColor : themeService.attrs.primaryTextColor]
        let highlightText = [NSAttributedStringKey.foregroundColor : themeService.attrs.textFieldEditingColor]
        
        let normalAttribute = NSMutableAttributedString(string: CKLocalization.string(byKey: "this_room_create"), attributes: normalText)
        
        let dateAttribute = NSMutableAttributedString(string: dateString + " by ", attributes: normalText)
        normalAttribute.append(dateAttribute)
        
        let highlightAttribute = NSMutableAttributedString(string: createrName, attributes: highlightText)
        normalAttribute.append(highlightAttribute)
        
        return normalAttribute
    }
    
    
    private func focusEditingTextField(textField: UITextField, isEditing: Bool = true) {
        
        let color = isEditing ? themeService.attrs.textFieldEditingColor : themeService.attrs.textFieldColor
        
        textField.borderColor = color
        textField.textColor = color
    }
}


extension CKEditRoomSettingsCell: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
//        isEnableSaveButton = true
        
        textField.backgroundColor = themeService.attrs.textFieldEditingBackground
        if textField == titleRoomTextField {
            focusEditingTextField(textField: titleRoomTextField, isEditing: true)
        } else {
            focusEditingTextField(textField: topicRoomTextField, isEditing: true)
        }
    }
    
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        textField.backgroundColor = themeService.attrs.textFieldBackground
        
        if textField == titleRoomTextField {
            focusEditingTextField(textField: titleRoomTextField, isEditing: false)

            if !(titleRoomTextField.text ?? "").isEmpty {
                titleRoomTextField.textColor = themeService.attrs.textFieldEditingColor
            }
        } else {
            focusEditingTextField(textField: topicRoomTextField, isEditing: false)

            if !(topicRoomTextField.text ?? "").isEmpty {
                topicRoomTextField.textColor = themeService.attrs.textFieldEditingColor
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        if textField == titleRoomTextField {
            topicRoomTextField.becomeFirstResponder()
        } else {
            topicRoomTextField.resignFirstResponder()
        }

        return true
    }
}
