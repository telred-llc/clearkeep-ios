//
//  CkAuthIndicatorViewController.swift
//  Riot
//
//  Created by Hiếu Nguyễn on 12/25/18.
//  Copyright © 2018 matrix.org. All rights reserved.
//

import UIKit

public class CkAuthIndicatorViewController: CkAuthenticationViewController {
    
    @IBOutlet weak var refreshUI: UIActivityIndicatorView!
    @IBOutlet weak var verificationLabel: UILabel!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        refreshUI.startAnimating()
        self.welcomeImageView.image = UIImage(named: "LaunchScreenRiot")
        self.isVerification = false
    }
    
    public override func finalizeInit() {
        super.finalizeInit()
    }
    
    public var isVerification: Bool {
        get {
            return verificationLabel.isHidden
        }
        
        set {
            verificationLabel.isHidden = !newValue
        }
    }
    
}
