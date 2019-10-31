//
//  CkLoginViewController.swift
//  Riot
//
//  Created by Sinbad Flyce on 12/19/18.
//  Copyright © 2018 matrix.org. All rights reserved.
//

import Foundation

final public class CkLoginViewController: CkAuthenticationViewController {
    
//    @IBOutlet weak var userIdTextField: UITextField!
//    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var userIdView: CKCustomTextField!
    @IBOutlet weak var passwordView: CKCustomTextField!
    @IBOutlet weak var signinButton: UIButton!
    
    
    public override func finalizeInit() {
        super.finalizeInit()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        userIdView.bindingData(title: CKLocalization.string(byKey: "auth_user_id"))
        userIdView.placeholder = CKLocalization.string(byKey: "auth_user_id_placeholder")
        userIdView.configReturnTypeKeyboard = .continue
        userIdView.triggerReturn = { textField in
            if textField == self.userIdView.contentTextField {
                self.passwordView.contentTextField.becomeFirstResponder()
            } else {
                self.userIdView.contentTextField.resignFirstResponder()
            }
        }
        
        passwordView.bindingData(title: CKLocalization.string(byKey: "auth_password"), isPassword: true)
        passwordView.placeholder = CKLocalization.string(byKey: "auth_password_placeholder")
        passwordView.configReturnTypeKeyboard = .done
        passwordView.triggerReturn = { textField in
            self.passwordView.contentTextField.resignFirstResponder()
        }
        
        themeService.typeStream.asObservable().subscribe { (themes) in
            let lightTheme = themes.element == ThemeType.light
            self.welcomeImageView.image = lightTheme ? #imageLiteral(resourceName: "logo_login_light") : #imageLiteral(resourceName: "logo_login_dark")
            self.view.backgroundColor = themes.element?.associatedObject.navBarBgColor
            
            self.signinButton.setBackgroundImage(lightTheme ? #imageLiteral(resourceName: "btn_start_room_light") : #imageLiteral(resourceName: "btn_start_room_dark"), for: .normal)
            self.signupButton.setBackgroundImage(#imageLiteral(resourceName: "btn_sign_up_dark"), for: .normal)
            self.forgotPassButton.setTitleColor(themes.element?.associatedObject.textFieldEditingColor, for: .normal)
        }.dispose()
        
    }

    public override func askForUpdating(completion: ([String : Any]) -> Void) {
        if let userid = userIdView.contentTextField.text, let password = self.passwordView.contentTextField.text {
            let parameters = ["userid": userid,
                              "password": password]
            completion(parameters)
        } else {
            completion([:])
        }
    }
}
