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
    func authenticationCancelSigningUp(_ authentication: CkAuthenticationViewController)
    func authenticationCancelResetPass(_ authentication: CkAuthenticationViewController)
    
    func authenticationFailStartSigningIn(withMessage message: String)
    func authenticationFailStartSigningUp(withMessage message: String)
    func authenticationFailStartResetPass(withMessage message: String)
    
    func authenticationWillStartSigningIn()
    func authenticationWillStartSigningUp()
    func authenticationWillStartResetPass()
}

public class CkAuthenticationViewController: MXKViewController, CkAuthorizerDelegate {
    
    @IBOutlet weak var authenticationScrollView: UIScrollView!
    @IBOutlet weak var welcomeImageView: UIImageView!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var forgotPassButton: UIButton!
    private var cancelSignupAlert: UIAlertController?
    
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
     DisposeBag
     */
    private let disposeBag = DisposeBag()

    /**
     finalize initial
     */
    public override func finalizeInit() {
        super.finalizeInit()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        bindingTheme()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    func bindingTheme() {
        // Binding navigation bar color
        themeService.attrsStream.subscribe(onNext: { [weak self] (theme) in
            self?.defaultBarTintColor = themeService.attrs.navBarBgColor
            self?.barTitleColor = themeService.attrs.primaryTextColor
        }).disposed(by: disposeBag)
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
    
    @IBAction func tappedForgotPassButton(_ sender: UIButton) {
        print("forgot pass")
        self.delegate?.authentication(self, requestAction: "forgot")
        
        if self.isKind(of: CkForgotPasswordViewController.self) {
            
            if let message = self.validateParameters() {
                self.delegate?.authenticationFailStartResetPass(withMessage: message)
                return
            }
            
            self.askForUpdating { (parameters: [String : Any]) in
                if let email = parameters["email"] as? String, let password = parameters["password"] as? String {
                    self.authorizer?.update(withUserId: email, password: password)
                }
                self.delegate?.authenticationWillStartResetPass()
                self.authorizer?.startResetPass()
            }
        }
    }
    
    /// Cancel  request
    @IBAction func cancelRequest() {
        /// Show alert to confirm action
        
        let messageKey = authorizer?.authType == MXKAuthenticationTypeForgotPassword  ? "auth_cancel_reset_pass" : "auth_cancel_registration"
        cancelSignupAlert = UIAlertController(title: nil,
                                              message: CKLocalization.string(byKey: messageKey),
                                              preferredStyle: .alert)
        guard  let alertController = cancelSignupAlert else {
            return
        }
        let okAction = UIAlertAction(title: "Yes", style: .destructive) { _ in
            if self.authorizer?.authType == MXKAuthenticationTypeForgotPassword {
                self.delegate?.authenticationCancelResetPass(self)
            } else {
                self.delegate?.authenticationCancelSigningUp(self)
            }
            
        }
        let cancelAction = UIAlertAction(title: "No", style: .default, handler: nil)
        
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func dismissCancelAlert() {
        if let cancelSignupAlert = cancelSignupAlert {
            cancelSignupAlert.dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: - PROBABLY OVERIDE
    public func askForUpdating(completion: ([String: Any]) -> Void) {}
    
    public func validateParameters() -> String? { return nil }
    
    public func isRegisteringWithEmail() -> Bool { return false }
    
    public func isResetPassword() -> Bool { return false }
    
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
            dismissCancelAlert()
            self.delegate?.authentication(self, onFailureDuringAuthError: error)
        }
    }
    
    internal func authorizer(_ authorizer: CkAuthorizer, onSuccessfulAuthCredentials credentials: MXCredentials) {
        if self.isVisible() {
            dismissCancelAlert()
            self.delegate?.authentication(self, onSuccessfulAuthCredentials: credentials)
        }
    }
    
    internal func resetPassSuccess() {
        if self.isVisible() {
            dismissCancelAlert()
        }
        
        let message = NSLocalizedString("auth_reset_password_success_message", tableName: "Vector", bundle: Bundle.main, value: "", comment: "")
        DispatchQueue.main.async {
            self.showAlert(message) {
                self.onSignIn()
            }
        }
        
    }

}
