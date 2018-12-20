//
//  CkSignUpViewController.swift
//  Riot
//
//  Created by Hiếu Nguyễn on 12/19/18.
//  Copyright © 2018 matrix.org. All rights reserved.
//

import UIKit

 public class CkSignUpViewController: CkAuthenticationViewController {

    @IBOutlet weak var signinButton: UIButton!
    
    
    public override func finalizeInit() {
        super.finalizeInit()
    }
    
   public override func viewDidLoad() {
        super.viewDidLoad()
        self.welcomeImageView.image = UIImage(named: "logo")
    }
    
    
    
    @IBAction func actionRegister(_ sender: UIButton) {
    }
    
    @IBAction func actionSignIn(_ sender: UIButton) {
    }

}
