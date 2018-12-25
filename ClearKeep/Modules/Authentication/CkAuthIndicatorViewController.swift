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
    public override func viewDidLoad() {
        super.viewDidLoad()
        refreshUI.startAnimating()
        self.welcomeImageView.image = UIImage(named: "LaunchScreenRiot")
    }
    
    public override func finalizeInit() {
        super.finalizeInit()
    }
    
  
}
