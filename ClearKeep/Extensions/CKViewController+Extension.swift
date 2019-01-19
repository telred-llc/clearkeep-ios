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
    func changeNavigationBar(color: UIColor) {
        var alphaValue: CGFloat = 1.0
        color.getRed(nil, green: nil, blue: nil, alpha: &alphaValue)
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage.init(color: color), for: .default)
        self.navigationController?.navigationBar.isTranslucent = alphaValue < 1
    }
}

// MARK: - MXKViewController extension

extension MXKViewController {
    
    // MARK: - CLASS VAR
    
    public class var nibName: String {
        return String(describing: self)
    }
    
    // MARK: - PUBLIC
    
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
}
