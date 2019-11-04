//
//  CkSignUpViewController.swift
//  Riot
//
//  Created by Hiếu Nguyễn on 12/19/18.
//  Copyright © 2018 matrix.org. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift

public class CkSignUpViewController: CkAuthenticationViewController, UITextFieldDelegate {
    
    @IBOutlet weak var registerView: UIView!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var signinButton: UIButton!
    
    @IBOutlet weak var userIdTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var repasswordTextField: UITextField!
    
    @IBOutlet weak var userIdTextFieldView: CKCustomTextField!
    @IBOutlet weak var passwordTFView: CKCustomTextField!
    @IBOutlet weak var repasswordTFView: CKCustomTextField!
    
    
    // MARK: - PROPERTY
    
    private var __isRegisteringWithEmail = false
    
    private var signupModel = (userId: "", password: "", repassword: "")
    
    // MARK: - PUBLIC
    
    public override func finalizeInit() {
        super.finalizeInit()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()

//        IQKeyboardManager.shared.enableAutoToolbar = false
        IQKeyboardManager.shared.keyboardDistanceFromTextField = 100

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tapGesture)
        
        userIdTextFieldView.bindingData(title: CKLocalization.string(byKey: "auth_user_id"))
        userIdTextFieldView.placeholder = CKLocalization.string(byKey: "auth_user_id_placeholder")
        userIdTextFieldView.configReturnTypeKeyboard = .continue
        userIdTextFieldView.edittingChangedHandler = { result in
            self.signupModel.userId = result ?? ""
        }
        userIdTextFieldView.triggerReturn = { textField in
            if textField == self.userIdTextFieldView.contentTextField {
                self.passwordTFView.contentTextField.becomeFirstResponder()
            }
        }
        
        passwordTFView.bindingData(title: CKLocalization.string(byKey: "auth_password"), isPassword: true)
        passwordTFView.placeholder = CKLocalization.string(byKey: "auth_password_placeholder")
        passwordTFView.configReturnTypeKeyboard = .continue
        passwordTFView.edittingChangedHandler = { result in
            self.signupModel.password = result ?? ""
        }
        passwordTFView.triggerReturn = { textField in
            if textField == self.passwordTFView.contentTextField {
                self.repasswordTFView.contentTextField.becomeFirstResponder()
            }
        }
        
        repasswordTFView.bindingData(title: CKLocalization.string(byKey: "auth_repeat_password"), isPassword: true)
        repasswordTFView.placeholder = CKLocalization.string(byKey: "auth_repeat_password_placeholder")
        repasswordTFView.configReturnTypeKeyboard = .done
        repasswordTFView.edittingChangedHandler = { result in
            self.signupModel.repassword = result ?? ""
        }
        repasswordTFView.triggerReturn = { textField in
                self.repasswordTFView.contentTextField.resignFirstResponder()
        }
        
        // observable themes
        themeService.typeStream.asObservable().subscribe { (themes) in
            let lightTheme = themes.element == ThemeType.light
            self.welcomeImageView.image = lightTheme ? #imageLiteral(resourceName: "logo_login_light") : #imageLiteral(resourceName: "logo_login_dark")
            self.view.backgroundColor = themes.element?.associatedObject.navBarBgColor
            
            self.registerButton.setBackgroundImage(lightTheme ? #imageLiteral(resourceName: "btn_start_room_light") : #imageLiteral(resourceName: "btn_start_room_dark"), for: .normal)
            
            self.signinButton.setBackgroundImage(#imageLiteral(resourceName: "btn_sign_up_dark"), for: .normal)
            self.setColorForAttribute()
        }.dispose()
        
    }
   
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Actions
    
    @IBAction func actionRegister(_ sender: UIButton) {
    }
    
    @IBAction func actionSignIn(_ sender: UIButton) {
    }
    
    //MARK: - Overrided
    
    public override func askForUpdating(completion: ([String : Any]) -> Void) {
        if !signupModel.userId.isEmpty && !signupModel.password.isEmpty {
            let parameters = ["userid": signupModel.userId,
                              "password": signupModel.password]

            // register with an email ?
            __isRegisteringWithEmail = MXTools.isEmailAddress(signupModel.userId)

            // fallback
            completion(parameters)
        } else {
            completion([:])
        }
    }
    
    public override func validateParameters() -> String? {
        
        var errorMsg: String? = nil
        
        if signupModel.userId.isEmpty {
            errorMsg = NSLocalizedString("auth_invalid_user_name", tableName: "Vector", bundle: Bundle.main, value: "", comment: "")
        } else if signupModel.password.isEmpty {
            errorMsg = NSLocalizedString("auth_missing_password", tableName: "Vector", bundle: Bundle.main, value: "", comment: "")
        } else if signupModel.password.count < 6 {
            errorMsg = NSLocalizedString("auth_invalid_password", tableName: "Vector", bundle: Bundle.main, value: "", comment: "")
        } else if signupModel.password != signupModel.repassword {
            errorMsg = NSLocalizedString("auth_password_dont_match", tableName: "Vector", bundle: Bundle.main, value: "", comment: "")
        }
        
        return errorMsg
    }
    
    public override func isRegisteringWithEmail() -> Bool {
        return __isRegisteringWithEmail
    }
}


extension CkSignUpViewController {
    
    private func setColorForAttribute() {
        let normalText = [NSAttributedStringKey.foregroundColor : #colorLiteral(red: 0.4392156863, green: 0.4392156863, blue: 0.4392156863, alpha: 1)]
        let highlightText = [NSAttributedStringKey.foregroundColor : themeService.attrs.textFieldEditingColor]
        
        let normalAttribute = NSMutableAttributedString(string: CKLocalization.string(byKey: "auth_sign_in_have_account"), attributes: normalText)
        let highlightAttribute = NSMutableAttributedString(string: CKLocalization.string(byKey: "auth_sign_in_button"), attributes: highlightText)
        
        normalAttribute.append(highlightAttribute)
        self.signinButton.setAttributedTitle(normalAttribute, for: .normal)
    }
}
