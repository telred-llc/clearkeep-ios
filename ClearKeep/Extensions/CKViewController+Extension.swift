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
    func showAlert(_ message: String, title: String = "ClearKeep", onComplete: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: Bundle.mxk_localizedString(forKey: "ok"), style: UIAlertActionStyle.default) { (_) in
            onComplete?()
            })
        self.present(alert, animated: true, completion: nil)
    }
    
    
    var safeArea: UIEdgeInsets {
        
        if #available(iOS 11.0, *) {
            return UIApplication.shared.keyWindow?.safeAreaInsets ?? .zero
        }
        
        return .zero
    }

}

// MARK: Custom Back Button Item
extension UIViewController: UIGestureRecognizerDelegate {
    
    func addCustomBackButton(_ image: UIImage? = UIImage(named: "back_button")?.withRenderingMode(.alwaysTemplate)) {
        
        let backButton = UIBarButtonItem(image: image,
                                         style: .plain,
                                         target: self,
                                         action:  #selector(handlePopViewController))
        
        backButton.tintColor = CKColor.Icon.back
        navigationItem.leftBarButtonItem = backButton
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    @objc
    private func handlePopViewController() {
        navigationController?.popViewController(animated: true)
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

public extension UIAlertController {
    func show() {
        let window = UIWindow(frame: UIScreen.main.bounds)
        let viewController = UIViewController()
        viewController.view.backgroundColor = .clear
        window.rootViewController = viewController
        window.windowLevel = UIWindowLevelAlert + 1  // Swift 5: UIWindow.Level.alert + 1
        window.makeKeyAndVisible()
        viewController.present(self, animated: true, completion: nil)
    }
}

extension UIApplication {
    
    @objc
    class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}

var topSpinner : UIView?

extension UIViewController {

    @objc
    func showSpinner(onView : UIView = (UIApplication.topViewController()?.view)!) {
        let spinnerView = UIView.init(frame: onView.bounds)
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.25)
        let ai = UIActivityIndicatorView.init(activityIndicatorStyle: .gray)
        ai.startAnimating()
        ai.center = spinnerView.center
        
        DispatchQueue.main.async {
            spinnerView.addSubview(ai)
            onView.addSubview(spinnerView)
        }
        
        topSpinner = spinnerView
    }

    @objc
    func removeSpinner() {
        DispatchQueue.main.async {
            topSpinner?.removeFromSuperview()
            topSpinner = nil
        }
    }
}
