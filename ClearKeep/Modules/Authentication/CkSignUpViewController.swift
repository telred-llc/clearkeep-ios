//
//  CkSignUpViewController.swift
//  Riot
//
//  Created by Hiếu Nguyễn on 12/19/18.
//  Copyright © 2018 matrix.org. All rights reserved.
//

import UIKit

public class CkSignUpViewController: CkAuthenticationViewController, UITextFieldDelegate {
    
    @IBOutlet weak var signinButton: UIButton!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var repassTextField: UITextField!
    
    public override func finalizeInit() {
        super.finalizeInit()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.welcomeImageView.image = UIImage(named: "logo")
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    // For pressing return on the keyboard to dismiss keyboard
    private func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        for textField in self.view.subviews where textField is UITextField {
            textField.resignFirstResponder()
        }
        return true
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
    
    
    @IBAction func actionRegister(_ sender: UIButton) {
    }
    
    @IBAction func actionSignIn(_ sender: UIButton) {
    }
    
}
