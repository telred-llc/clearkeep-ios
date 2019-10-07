//
//  AppUtils.swift
//  Riot
//
//  Created by vmodev on 9/27/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation
class AppUtils {

    static func openURL(_ url: String) {
        if url.isEmpty {
            return
        }
        let urlOpen: URL = URL(string: url)!
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(urlOpen, options: [:], completionHandler: nil)
        } else {
            // Fallback on earlier versions
            UIApplication.shared.openURL(urlOpen)
        }
    }
    
    static func openURL(url: URL?) {
        if url == nil {
            return
        }
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url!, options: [:], completionHandler: nil)
        } else {
            // Fallback on earlier versions
            UIApplication.shared.openURL(url!)
        }
    }
    
    static func openEmail(_ email :String) {
        if email.isEmpty {
            return
        }
        let url = URL(string: "mailto:\(email)")!
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
}
