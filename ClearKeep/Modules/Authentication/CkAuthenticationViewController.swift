//
//  CkAuthenticationViewController.swift
//  Riot
//
//  Created by Sinbad Flyce on 11/27/18.
//  Copyright © 2018 matrix.org. All rights reserved.
//

import Foundation
import MatrixKit

protocol CkAuthenticationViewControllerDelegate: class {
    func authentication(_ authentication: CkAuthenticationViewController, requestAction action: String)
}

public class CkAuthenticationViewController: MXKViewController {
    
    @IBOutlet weak var authenticationScrollView: UIScrollView!
    @IBOutlet weak var welcomeImageView: UIImageView!
    @IBOutlet weak var signupButton: UIButton!
    
    weak var delegate: CkAuthenticationViewControllerDelegate?
    
    /**
     Authorizer.
     */
    internal var authorizer: CkAuthorizer!
    
    /**
     Force a registration process based on a predefined set of parameters.
     Use this property to pursue a registration from the next_link sent in an email validation email.
     */
    @objc public var externalRegistrationParameters: NSDictionary!
    
    public override func finalizeInit() {
        super.finalizeInit()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.signupButton != nil {
            self.signupButton.layer.borderWidth = 1
            self.signupButton.layer.borderColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        }
    }
    
    // MARK: - Actions

    @IBAction func onEmailPress() {
    
    }

    @IBAction func onUsernamePress() {
    
    }
    
    @IBAction func onSignIn() {
        self.delegate?.authentication(self, requestAction: "login")
    }
    
    @IBAction func onSignUp() {
        self.delegate?.authentication(self, requestAction: "register")
    }
}
