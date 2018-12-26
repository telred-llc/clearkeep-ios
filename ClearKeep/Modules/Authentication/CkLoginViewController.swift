//
//  CkLoginViewController.swift
//  Riot
//
//  Created by Sinbad Flyce on 12/19/18.
//  Copyright © 2018 matrix.org. All rights reserved.
//

import Foundation

final public class CkLoginViewController: CkAuthenticationViewController {
    
    @IBOutlet weak var userIdTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    public override func finalizeInit() {
        super.finalizeInit()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()        
        self.welcomeImageView.image = UIImage(named: "logo")
        self.userIdTextField.text = "test"
        self.passwordTextField.text = "111111"        
    }

    public override func askForUpdating(completion: ([String : Any]) -> Void) {
        if let userid = self.userIdTextField?.text, let password = self.passwordTextField?.text {
            let parameters = ["userid": userid,
                              "password": password]
            completion(parameters)
        } else {
            completion([:])
        }
    }
}

extension CkLoginViewController {
}
