//
//  CkLoginViewController.swift
//  Riot
//
//  Created by Sinbad Flyce on 12/19/18.
//  Copyright © 2018 matrix.org. All rights reserved.
//

import Foundation

final public class CkLoginViewController: CkAuthenticationViewController {
    
    public override func finalizeInit() {
        super.finalizeInit()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()        
        self.welcomeImageView.image = UIImage(named: "logo")
    }

}
