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
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var verificationLabel: UILabel!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        refreshUI.startAnimating()
        self.welcomeImageView.image = UIImage(named: "LaunchScreenRiot")
        cancelButton.isHidden = true
        verificationLabel.isHidden = true
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cancelButton.isHidden = true
        verificationLabel.isHidden = true
    }
    
    public override func finalizeInit() {
        super.finalizeInit()
    }
    
    public var displayType: DisplayAuthenticationStyle = .indicator {
        didSet {
            var isVerification = true
            switch displayType {
            case .register:
                verificationLabel.text = CKLocalization.string(byKey: "auth_register_waiting_verify_mail")
            case .forgot:
                verificationLabel.text = CKLocalization.string(byKey: "auth_reset_pass_waiting_verify_mail")
            default:
                isVerification = false
                verificationLabel.text = ""
            }
            cancelButton.isHidden = !isVerification
            verificationLabel.isHidden = !isVerification
        }
    }
    
}
