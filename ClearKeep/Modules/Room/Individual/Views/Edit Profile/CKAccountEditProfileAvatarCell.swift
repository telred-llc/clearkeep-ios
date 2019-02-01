//
//  CKAccountEditProfileAvatarCell.swift
//  Riot
//
//  Created by Hiếu Nguyễn on 1/23/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

class CKAccountEditProfileAvatarCell: CKAccountEditProfileBaseCell, UITextFieldDelegate {
    
    
    // MARK: - OUTLET

    @IBOutlet weak var avaImage: CKImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var cameraButton: UIButton!
    
    // MARK: - PROPERTY
    
    /**
     TapHandler
     */
    internal var tapHandler: (() -> Void)?
    
    /**
     CameraHandler
     */
    internal var cameraHandler: (() -> Void)?

    /**
     edittingChangedHandler
     */
    internal var edittingChangedHandler: ((String?) -> Void)?
    
    
    // MARK: - OVERRIDE
    override func awakeFromNib() {
        super.awakeFromNib()
//        avaImage.defaultBackgroundColor = UIColor.clear
        avaImage.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin]
        avaImage.contentMode = UIView.ContentMode.scaleAspectFill
        avaImage.clipsToBounds = true
        avaImage.layer.cornerRadius = 9
        avaImage.layer.borderWidth = 2
        avaImage.layer.borderColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        nameTextField.delegate = self
        cameraButton.setImage(UIImage(named: "ic_account_editprofile_camera"), for: .normal)
        self.cameraButton.addTarget(self, action: #selector(onClickedTakePictureButton(_:)), for: .touchUpInside)
        self.nameTextField.addTarget(self, action: #selector(edittingChanged), for: .editingChanged)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        avaImage.isUserInteractionEnabled = true
        avaImage.addGestureRecognizer(tapGestureRecognizer)
    }
    
    // MARK: - PUBLIC
    public func setAvatarImageUrl(urlString: String, previewImage: UIImage?)  {
        avaImage.enableInMemoryCache = true
        avaImage.setImageURL(
            urlString, withType: nil,
            andImageOrientation: UIImageOrientation.up,
            previewImage: previewImage)
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameTextField {
            nameTextField.resignFirstResponder()
        }
        return true
    }


    
    // MARK: - ACTION
    
    @objc func edittingChanged(textField: UITextField) {
        edittingChangedHandler?(textField.text)
    }
    
    @objc func onClickedTakePictureButton(_ sender: Any) {
        cameraHandler?()
    }
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        tapHandler?()
    }
}
