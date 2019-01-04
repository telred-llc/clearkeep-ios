//
//  CKRoomPageViewController.swift
//  Riot
//
//  Created by Pham Hoa on 1/3/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

class CKRoomPageViewController: UIViewController {

    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.title = "Room"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.red
    }
}
