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
    
    // MARK: - PROPERTY
    
    private var __isRegisteringWithEmail = false
    
    // MARK: - PUBLIC
    
    public override func finalizeInit() {
        super.finalizeInit()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.welcomeImageView.image = UIImage(named: "logo")

        IQKeyboardManager.shared.enableAutoToolbar = false
        IQKeyboardManager.shared.keyboardDistanceFromTextField = 100

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
   
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        registerView.applyGradient(
            colours: [UIColor].init(arrayLiteral: #colorLiteral(red: 0.09481538087, green: 0.7234704494, blue: 0.7655344605, alpha: 1),#colorLiteral(red: 0.4508578777, green: 0.9882974029, blue: 0.8376303315, alpha: 1)),
            locations: [0.0, 0.5, 1.0])
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == userIdTextField {
            passwordTextField.becomeFirstResponder()
        } else {
            passwordTextField.resignFirstResponder()
        }
        
        if textField == passwordTextField {
            repasswordTextField.becomeFirstResponder()
        } else {
            repasswordTextField.resignFirstResponder()
        }
        
        if textField == repasswordTextField {
            repasswordTextField.resignFirstResponder()
        }
        return true
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
        if let userid = self.userIdTextField?.text, let password = self.passwordTextField?.text {
            let parameters = ["userid": userid,
                              "password": password]
            
            // register with an email ?
            __isRegisteringWithEmail = MXTools.isEmailAddress(userid)
            
            // fallback
            completion(parameters)
        } else {
            completion([:])
        }
    }
    
    public override func validateParameters() -> String? {
        
        var errorMsg: String? = nil
        
        if userIdTextField.text?.count == 0 {
            errorMsg = NSLocalizedString("auth_invalid_user_name", tableName: "Vector", bundle: Bundle.main, value: "", comment: "")
        } else if passwordTextField.text?.count == 0 {
            errorMsg = NSLocalizedString("auth_missing_password", tableName: "Vector", bundle: Bundle.main, value: "", comment: "")
        } else if let pw = passwordTextField.text, pw.count < 6 {
            errorMsg = NSLocalizedString("auth_invalid_password", tableName: "Vector", bundle: Bundle.main, value: "", comment: "")
        } else if let pw = passwordTextField.text, let rpw = repasswordTextField.text, pw != rpw {
            errorMsg = NSLocalizedString("auth_password_dont_match", tableName: "Vector", bundle: Bundle.main, value: "", comment: "")
        }
        
        return errorMsg
    }
    
    public override func isRegisteringWithEmail() -> Bool {
        return __isRegisteringWithEmail
    }
}


