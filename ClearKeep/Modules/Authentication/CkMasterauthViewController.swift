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
    
    private let authorizer = CkAuthorizer(userName: "", password: "")
    
    @objc public var externalRegistrationParameters: NSDictionary!
    
    public var displayStyle: DisplayAuthenticationStyle = .login
    
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
            add(asChildViewController: loginViewController)
        } else if displayStyle == .forgot {
            remove(asChildViewController: loginViewController)
            remove(asChildViewController: registerViewController)
            add(asChildViewController: forgotPwdViewController)
        } else if displayStyle == .register {
            remove(asChildViewController: loginViewController)
            remove(asChildViewController: forgotPwdViewController)
            add(asChildViewController: registerViewController)
        } else if displayStyle == .indicator {
            remove(asChildViewController: loginViewController)
            remove(asChildViewController: forgotPwdViewController)
            remove(asChildViewController: registerViewController)
            add(asChildViewController: indicatorViewController)
        }
        
    }

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
            self.updateView()
        } else if action == "forgot" {
            self.displayStyle = .forgot
            self.updateView()
        } else if action == "register" {
            self.displayStyle = .register
            self.updateView()
        } else if action == "indicator" {
            self.displayStyle = . indicator
            self.updateView()
        }
    }
    
    func authenticationWillStartSigningUp() {        
    }
    
    func authenticationWillStartSigningIn() {
        
    }
}
