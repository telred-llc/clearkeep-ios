//
//  CkForgotPasswordViewController.swift
//  Riot
//
//  Created by Sinbad Flyce on 12/19/18.
//  Copyright © 2018 matrix.org. All rights reserved.
//

import Foundation

final public class CkForgotPasswordViewController: CkAuthenticationViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var newPassTextField: UITextField!
    @IBOutlet weak var confirmPassTextField: UITextField!
    @IBOutlet weak var resetPassButton: Button!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    
    private var __isResetPassword = false
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        emailTextField.text = ""
        newPassTextField.text = ""
        confirmPassTextField.text = ""
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resetPassButton.applyGradient(
            colours: [UIColor].init(arrayLiteral: #colorLiteral(red: 0.09481538087, green: 0.7234704494, blue: 0.7655344605, alpha: 1),#colorLiteral(red: 0.4508578777, green: 0.9882974029, blue: 0.8376303315, alpha: 1)),
            locations: [0.0, 0.5, 1.0])
    }
    
    public override func validateParameters() -> String? {
        
        var errorMessage: String? = nil
        
        if emailTextField.text?.count == 0 {
            errorMessage = NSLocalizedString("auth_missing_email", tableName: "Vector", bundle: Bundle.main, value: "", comment: "")
        } else if !MXTools.isEmailAddress(emailTextField.text ?? "") {
            errorMessage = NSLocalizedString("auth_invalid_email", tableName: "Vector", bundle: Bundle.main, value: "", comment: "")
        } else if newPassTextField.text?.count == 0 {
            errorMessage = NSLocalizedString("auth_missing_password", tableName: "Vector", bundle: Bundle.main, value: "", comment: "")
        } else if let newPass = newPassTextField.text, newPass.count < 6 {
            errorMessage = NSLocalizedString("auth_invalid_password", tableName: "Vector", bundle: Bundle.main, value: "", comment: "")
        } else if let newPass = newPassTextField.text, let confirmPass = confirmPassTextField.text, newPass != confirmPass {
            errorMessage = NSLocalizedString("auth_password_dont_match", tableName: "Vector", bundle: Bundle.main, value: "", comment: "")
        }
        
        return errorMessage
    }
    
    public override func askForUpdating(completion: ([String : Any]) -> Void) {
        if let userId = self.emailTextField.text, let password = self.newPassTextField.text {
            let parameters = ["email": userId,
                              "password": password]
            __isResetPassword = true
            completion(parameters)
        } else {
            completion([:])
        }
    }
    
    public override func isResetPassword() -> Bool {
         return __isResetPassword
    }
    
}
