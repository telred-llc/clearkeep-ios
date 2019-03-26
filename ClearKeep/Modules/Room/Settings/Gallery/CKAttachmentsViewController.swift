//
//  CKAttachmentsViewController.swift
//  Riot
//
//  Created by Developer Super on 3/26/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

class CKAttachmentsViewController: MXKAttachmentsViewController {

    private var kRiotDesignValuesDidChangeThemeNotificationObserver: Any?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        kRiotDesignValuesDidChangeThemeNotificationObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.riotDesignValuesDidChangeTheme, object: nil, queue: OperationQueue.main, using: { [weak self] notif in
            if let weakSelf = self {
                weakSelf.userInterfaceThemeDidChange()
            }
        })
        
        self.userInterfaceThemeDidChange()
    }
    
    func userInterfaceThemeDidChange() {
        self.view.backgroundColor = kRiotPrimaryBgColor
        self.defaultBarTintColor = .red
        self.barTitleColor = kRiotPrimaryTextColor
        self.activityIndicator.backgroundColor = kRiotOverlayColor
        
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.tintColor = CKColor.Misc.primaryGreenColor
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.isTranslucent = true
        self.backButton.image = UIImage(named: "ic_x_close")
    }
    
    override func destroy() {
        if (kRiotDesignValuesDidChangeThemeNotificationObserver != nil) {
            NotificationCenter.default.removeObserver(kRiotDesignValuesDidChangeThemeNotificationObserver!)
            kRiotDesignValuesDidChangeThemeNotificationObserver = nil
        }
        super.destroy()
    }

}
