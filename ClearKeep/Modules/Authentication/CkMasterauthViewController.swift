//
//  CkMasterauthViewController.swift
//  Riot
//
//  Created by Sinbad Flyce on 12/19/18.
//  Copyright © 2018 matrix.org. All rights reserved.
//

import Foundation
import MatrixKit

public enum DisplayAuthenticationStyle {
    case login
    case register
    case forgot
    case indicator
}

final public class CkMasterauthViewController: MXKViewController, CkAuthenticationViewControllerDelegate {
    
    private let authorizer = CkAuthorizer(userId: "", password: "")
    
    @objc public var externalRegistrationParameters: NSDictionary!
    
    public var displayStyle: DisplayAuthenticationStyle = .login
    
    private var lastStyle: DisplayAuthenticationStyle = .login
    
    private lazy var loginViewController: CkLoginViewController = {
        var viewController = CkLoginViewController(nibName: "CkLoginViewController", bundle: nil)
        viewController.delegate = self        
        viewController.attach(newAuthorizer: authorizer)
        self.add(asChildViewController: viewController)
        return viewController
    }()

    private lazy var registerViewController: CkSignUpViewController = {
        var viewController = CkSignUpViewController(nibName: "CkSignUpViewController", bundle: nil)
        viewController.delegate = self
        viewController.attach(newAuthorizer: authorizer)
        self.add(asChildViewController: viewController)
        return viewController
    }()
    
    private lazy var indicatorViewController: CkAuthIndicatorViewController = {
        var viewController = CkAuthIndicatorViewController(nibName: "CkAuthIndicatorViewController", bundle: nil)
        viewController.delegate = self
        viewController.attach(newAuthorizer: authorizer)
        self.add(asChildViewController: viewController)
        return viewController
    }()

    private lazy var forgotPwdViewController: CkForgotPasswordViewController = {
        var viewController = CkForgotPasswordViewController(nibName: "CkForgotPasswordViewController", bundle: nil)
        viewController.delegate = self
        viewController.attach(newAuthorizer: authorizer)
        self.add(asChildViewController: viewController)
        return viewController
    }()

    // MARK: - Private
    
    private func add(asChildViewController viewController: UIViewController) {
        // Add Child View Controller
        addChildViewController(viewController)
        
        // Add Child View as Subview
        view.addSubview(viewController.view)
        
        // Configure Child View
        viewController.view.frame = view.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Notify Child View Controller
        viewController.didMove(toParentViewController: self)
    }
 
    private func remove(asChildViewController viewController: UIViewController) {
        // Notify Child View Controller
        viewController.willMove(toParentViewController: nil)
        
        // Remove Child View From Superview
        viewController.view.removeFromSuperview()
        
        // Notify Child View Controller
        viewController.removeFromParentViewController()
    }

    private func setupView() {
        if displayStyle == .login {
            remove(asChildViewController: forgotPwdViewController)
            remove(asChildViewController: registerViewController)
            
            // reset verification
            indicatorViewController.isVerification = false
            add(asChildViewController: loginViewController)
        } else if displayStyle == .forgot {
            remove(asChildViewController: loginViewController)
            remove(asChildViewController: registerViewController)
            
            // reset verification
            indicatorViewController.isVerification = false
            add(asChildViewController: forgotPwdViewController)
        } else if displayStyle == .register {
            remove(asChildViewController: loginViewController)
            remove(asChildViewController: forgotPwdViewController)
            add(asChildViewController: registerViewController)
        } else if displayStyle == .indicator {
            remove(asChildViewController: loginViewController)
            remove(asChildViewController: forgotPwdViewController)
            remove(asChildViewController: registerViewController)
            
            // maybe the registration of user email
            indicatorViewController.isVerification = registerViewController.isRegisteringWithEmail()
            add(asChildViewController: indicatorViewController)
        }
    }

    private func finalAuthentication(withUserId userId: String) {
        // Tag the first Login
        AppDelegate.the().isFirstLogin = true
        
        if let nc = self.navigationController {
            nc.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    private func alert(withMessage message: String) {
        let alert: UIAlertController = UIAlertController(
            title: nil,
            message: message, preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Close", style: .default) { (action: UIAlertAction) in
        }
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Public
    
    public func updateView() {
        self.setupView()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.setupView()
    }
}

extension CkMasterauthViewController {
    
    func authentication(_ authentication: CkAuthenticationViewController, requestAction action: String) {
        if action == "login" {
            self.displayStyle = .login
            self.lastStyle = .login
            self.updateView()
        } else if action == "forgot" {
            self.displayStyle = .forgot
            self.lastStyle = .forgot
            self.updateView()
        } else if action == "register" {
            self.displayStyle = .register
            self.lastStyle = .register
            self.updateView()
        } else if action == "indicator" {
            self.displayStyle = . indicator
            self.updateView()
        }
    }
    
    func authenticationWillStartSigningUp() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
            self.displayStyle = . indicator
            self.updateView()
        }
    }
    
    func authenticationWillStartSigningIn() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
            self.displayStyle = . indicator
            self.updateView()
        }
    }
    
    func authenticationFailStartSigningIn(withMessage message: String) {
        self.alert(withMessage: message)
    }
    
    func authenticationFailStartSigningUp(withMessage message: String) {
        self.alert(withMessage: message)
    }
    
    func authenticationCancelSigningUp(_ authentication: CkAuthenticationViewController) {
        self.authentication(authentication, requestAction: "register")
    }
    
    func authentication(_ authentication: CkAuthenticationViewController, onFailureDuringAuthError error: Error) {
        
        self.alert(withMessage: error.localizedDescription)
        
        if self.lastStyle == .login {
            self.authentication(authentication, requestAction: "login")
        } else if self.lastStyle == .register {
            self.authentication(authentication, requestAction: "register")
        }
    }
    
    func authentication(_ authentication: CkAuthenticationViewController, onSuccessfulAuthCredentials credentials: MXCredentials) {
        self.finalAuthentication(withUserId: credentials.userId ?? "unknown")
    }
}
