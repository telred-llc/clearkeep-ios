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
    func authentication(_ authentication: CkAuthenticationViewController, onSuccessfulAuthCredentials credentials: MXCredentials)
    func authentication(_ authentication: CkAuthenticationViewController, onFailureDuringAuthError error: Error)
    
    func authenticationFailStartSigningIn(withMessage message: String)
    func authenticationFailStartSigningUp(withMessage message: String)
    
    func authenticationWillStartSigningIn()
    func authenticationWillStartSigningUp()
}

public class CkAuthenticationViewController: MXKViewController, CkAuthorizerDelegate {
    
    @IBOutlet weak var authenticationScrollView: UIScrollView!
    @IBOutlet weak var welcomeImageView: UIImageView!
    @IBOutlet weak var signupButton: UIButton!
    
    /**
     Delegate
     */
    weak var delegate: CkAuthenticationViewControllerDelegate?
    
    /**
     Authorizer.
     */
    private var authorizer: CkAuthorizer?
    
    /**
     Force a registration process based on a predefined set of parameters.
     Use this property to pursue a registration from the next_link sent in an email validation email.
     */
    @objc public var externalRegistrationParameters: NSDictionary!
    
    /**
     finalize initial
     */
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
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
        
    @IBAction func onSignIn() {
        self.delegate?.authentication(self, requestAction: "login")
        
        if self.isKind(of: CkLoginViewController.self) {
            
            if let message = self.validateParameters() {
                self.delegate?.authenticationFailStartSigningIn(withMessage: message)
                return
            }
            
            self.askForUpdating { (parameters: [String : Any]) in
                if let userid = parameters["userid"] as? String, let password = parameters["password"] as? String {
                    self.authorizer?.update(withUserId: userid, password: password)
                }
                self.delegate?.authenticationWillStartSigningIn()                
                self.authorizer?.startSigningIn()
            }
        }
    }
    
    @IBAction func onSignUp() {
        self.delegate?.authentication(self, requestAction: "register")
        
        if self.isKind(of: CkSignUpViewController.self) {
            
            if let message = self.validateParameters() {
                self.delegate?.authenticationFailStartSigningUp(withMessage: message)
                return
            }

            self.askForUpdating { (parameters: [String : Any]) in
                if let userid = parameters["userid"] as? String, let password = parameters["password"] as? String {
                    self.authorizer?.update(withUserId: userid, password: password)
                }
                self.delegate?.authenticationWillStartSigningUp()
                self.authorizer?.startSigningUp()
            }
        }
    }
    
    // MARK: - PROBABLY OVERIDE
    public func askForUpdating(completion: ([String: Any]) -> Void) {}
    
    public func validateParameters() -> String? { return nil }
    
    public func isRegisteringWithEmail() -> Bool { return false }
}

extension CkAuthenticationViewController {
    
    public func attach(newAuthorizer authorizer: CkAuthorizer) {
        authorizer.delegates.add(delegate: self)
        self.authorizer = authorizer
    }
    
    public func isVisible() -> Bool {
        return (self.isViewLoaded && self.view.window != nil)
    }
}

extension CkAuthenticationViewController {
    
    internal func authorizer(_ authorizer: CkAuthorizer, onFailureDuringAuthError error: Error) {
        if self.isVisible() {
            self.delegate?.authentication(self, onFailureDuringAuthError: error)
        }
    }
    
    internal func authorizer(_ authorizer: CkAuthorizer, onSuccessfulAuthCredentials credentials: MXCredentials) {
        if self.isVisible() {
            self.delegate?.authentication(self, onSuccessfulAuthCredentials: credentials)
        }
    }
}
