//
//  CKViewController+Extension.swift
//  Riot
//
//  Created by Pham Hoa on 1/4/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

// MARK: - UIViewController extension

extension UIViewController {
    
    /// Remove back bar button title when pushing a view controller.
    /// This method should be called on the previous controller in UINavigationController stack.
    func vc_removeBackTitle() {
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    /**
     This allows you change navigation color
     */
    func changeNavigationBar(color: UIColor) {
        var alphaValue: CGFloat = 1.0
        color.getRed(nil, green: nil, blue: nil, alpha: &alphaValue)
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage.init(color: color), for: .default)
        self.navigationController?.navigationBar.isTranslucent = alphaValue < 1
    }
    
    /**
     Show alert in Self
     */
    func showAlert(_ message: String, onComplete: (() -> Void)? = nil) {
        let alert = UIAlertController(title: "ClearKeep", message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: Bundle.mxk_localizedString(forKey: "ok"), style: UIAlertActionStyle.default) { (_) in
            onComplete?()
            })
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: - MXKViewController extension

@objc extension MXKViewController {

    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return themeService.attrs.statusBarStyle
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isTranslucent = false
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.rageShakeManager = RageShakeManager.sharedManager() as? MXKResponderRageShaking
    }
    
    // MARK: - CLASS VAR
    
    /**
     By our pattern, class name is same nib name
     */
    public class var nibName: String {
        return String(describing: self)
    }
    
    /**
     By our pattern, an UINib probably initilaze by its nib name
     */
    class var nib: UINib {
        return UINib.init(nibName: self.nibName, bundle: nil)
    }
    
    class func instance() -> Self {
        return self.init(nibName: self.nibName, bundle: nil)
    }
    
    class func instanceNavigation(completion: ((_ instance: MXKViewController) -> Void)?) -> UINavigationController {
        let vc = self.instance()
        completion?(vc)
        return UINavigationController(rootViewController: vc)
    }
    
    // MARK: - PUBLIC
    
    /**
     Add matrix sessions from another matrix sessions
     */
    public func importSession(_ mxSessions: [Any]!) {
        
        // sure session is available
        if let sessions = mxSessions {
            
            // loop through all sessions
            for session in sessions {
                
                // if available then add them
                if let s = session as? MXSession {
                    self.addMatrixSession(s)
                }
            }
        }
    }
    
    /**
     Checking how is the controller be present or pushed
     */
    public func isModel() -> Bool {
        
        // it is present vc
        if self.presentationController != nil { return true }
        
        // it has nvc, but nvc.p.p == nvc
        if let nvc = self.navigationController {
            if nvc.presentationController?.presentedViewController == nvc { return true }
        }
        
        // it has tvc, but tvc.p is kind of uitvc
        if let tvc = self.tabBarController {
            if let ptvc = tvc.presentedViewController, ptvc.isKind(of: UITabBarController.self) { return true}
        }
        
        // it was pushed
        return false
    }
    
    /**
     Check view of controller is visible
     */
    public func isViewVisible() -> Bool {
        return (self.isViewLoaded && self.view?.window != nil)
    }
}


// MARK: - MXKTableViewController Extension

@objc extension MXKTableViewController {
    
    /**
     By our pattern, class name is same nib name
     */
    public class var nibName: String {
        return String(describing: self)
    }
    
    /**
     By our pattern, an UINib probably initilaze by its nib name
     */
    class var nib: UINib {
        return UINib.init(nibName: self.nibName, bundle: nil)
    }
    
    @objc class func instance() -> Self {
        return self.init(nibName: self.nibName, bundle: nil)
    }
    
    class func instanceNavigation(completion: ((_ instance: MXKTableViewController) -> Void)?) -> UINavigationController {
        let vc = self.instance()
        completion?(vc)
        return UINavigationController(rootViewController: vc)
    }
}
