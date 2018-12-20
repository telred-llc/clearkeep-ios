//
//  CkAppDelegate.swift
//  Riot
//
//  Created by Sinbad Flyce on 11/26/18.
//  Copyright © 2018 matrix.org. All rights reserved.
//

import Foundation
@objc extension AppDelegate {
    
    public func useCkStoryboard(_ application: UIApplication) {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        
        let storyboard = UIStoryboard(name: "MainEx", bundle: nil)        
        let initialViewController = storyboard.instantiateViewController(withIdentifier: "CkSplitViewController") as! UISplitViewController
        initialViewController.delegate = self
        
        self.window?.rootViewController = initialViewController
        self.window?.makeKeyAndVisible()
    }
    
}
