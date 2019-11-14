//
//  CkForgotPasswordViewController.swift
//  Riot
//
//  Created by Sinbad Flyce on 12/19/18.
//  Copyright © 2018 matrix.org. All rights reserved.
//

import Foundation

final public class CkForgotPasswordViewController: CkAuthenticationViewController {
    
    @IBOutlet weak var userEmailTextFieldView: CKCustomTextField!
    @IBOutlet weak var passwordTFView: CKCustomTextField!
    @IBOutlet weak var rePasswordTFView: CKCustomTextField!
    
    @IBOutlet weak var hintLabel: UILabel!
    
    @IBOutlet weak var resetPasswordButton: UIButton!
    @IBOutlet weak var signInButton: UIButton!
    
    
    private var __isResetPassword = false
    
    private var resetPasswordModel = (userId: "", password: "", repassword: "")
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tapGesture)
        bindingData()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        userEmailTextFieldView.resetData()
        passwordTFView.resetData()
        rePasswordTFView.resetData()
    }
    
    public override func validateParameters() -> String? {
        
        var errorMessage: String? = nil
        
        if resetPasswordModel.userId.isEmpty {
            errorMessage = NSLocalizedString("auth_missing_email", tableName: "Vector", bundle: Bundle.main, value: "", comment: "")
        } else if !MXTools.isEmailAddress(resetPasswordModel.userId) {
            errorMessage = NSLocalizedString("auth_invalid_email", tableName: "Vector", bundle: Bundle.main, value: "", comment: "")
        } else if resetPasswordModel.password.isEmpty {
            errorMessage = NSLocalizedString("auth_missing_password", tableName: "Vector", bundle: Bundle.main, value: "", comment: "")
        } else if resetPasswordModel.password.count < 6 {
            errorMessage = NSLocalizedString("auth_invalid_password", tableName: "Vector", bundle: Bundle.main, value: "", comment: "")
        } else if resetPasswordModel.password != resetPasswordModel.repassword {
            errorMessage = NSLocalizedString("auth_password_dont_match", tableName: "Vector", bundle: Bundle.main, value: "", comment: "")
        }
        
        return errorMessage
    }
    
    public override func askForUpdating(completion: ([String : Any]) -> Void) {
        if !resetPasswordModel.userId.isEmpty && !resetPasswordModel.password.isEmpty {
            let parameters = ["email": resetPasswordModel.userId,
                              "password": resetPasswordModel.password]
            __isResetPassword = true
            completion(parameters)
        } else {
            completion([:])
        }
    }
    
    public override func isResetPassword() -> Bool {
         return __isResetPassword
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
    
}

extension CkForgotPasswordViewController {
    
    private func bindingData() {
        
        hintLabel.text = CKLocalization.string(byKey: "auth_new_password_hint_label")
        
        userEmailTextFieldView.bindingData(title: CKLocalization.string(byKey: "auth_user_id"))
        userEmailTextFieldView.placeholder = CKLocalization.string(byKey: "auth_user_id_placeholder")
        userEmailTextFieldView.configReturnTypeKeyboard = .continue
        userEmailTextFieldView.edittingChangedHandler = { result in
            self.resetPasswordModel.userId = result ?? ""
        }
        userEmailTextFieldView.triggerReturn = { textField in
            if textField == self.userEmailTextFieldView.contentTextField {
                self.passwordTFView.contentTextField.becomeFirstResponder()
            }
        }
        
        passwordTFView.bindingData(title: CKLocalization.string(byKey: "auth_new_password"),
                                   isPassword: true)
        passwordTFView.placeholder = CKLocalization.string(byKey: "auth_new_password_placeholder")
        passwordTFView.configReturnTypeKeyboard = .continue
        passwordTFView.edittingChangedHandler = { result in
            self.resetPasswordModel.password = result ?? ""
        }
        passwordTFView.triggerReturn = { textField in
            if textField == self.passwordTFView.contentTextField {
                self.rePasswordTFView.contentTextField.becomeFirstResponder()
            }
        }
        
        rePasswordTFView.bindingData(title: CKLocalization.string(byKey: "auth_confirm_new_password"),
                                     isPassword: true)
        rePasswordTFView.placeholder = CKLocalization.string(byKey: "auth_confirm_new_password_placeholder")
        rePasswordTFView.configReturnTypeKeyboard = .done
        rePasswordTFView.edittingChangedHandler = { result in
            self.resetPasswordModel.repassword = result ?? ""
        }
        rePasswordTFView.triggerReturn = { textField in
            if textField == self.rePasswordTFView.contentTextField {
                self.rePasswordTFView.contentTextField.resignFirstResponder()
            }
        }
        
        // observable themes
        themeService.typeStream.asObservable().subscribe { (themes) in
            let lightTheme = themes.element == ThemeType.light
            self.welcomeImageView.image = lightTheme ? #imageLiteral(resourceName: "logo_login_light") : #imageLiteral(resourceName: "logo_login_dark")
            self.view.backgroundColor = themes.element?.associatedObject.primaryBgColor
            self.hintLabel.textColor = themes.element?.associatedObject.hintText
            self.resetPasswordButton.setBackgroundImage(lightTheme ? #imageLiteral(resourceName: "btn_start_room_light") : #imageLiteral(resourceName: "btn_start_room_dark"), for: .normal)
            
            self.signInButton.setBackgroundImage(#imageLiteral(resourceName: "btn_sign_up_dark"), for: .normal)
        }.dispose()
    }
}
