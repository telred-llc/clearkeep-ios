//
//  CKRoomViewController.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/4/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation
import MatrixKit

extension RoomViewController {
    
    @objc public func rewrite(method: String, parameters: [String: Any]) -> Bool {
        return false
    }
}

@objc final class CKRoomViewController: RoomViewController {
    public override class func nib() -> UINib? {
        return UINib.init(
            nibName: String(describing: RoomViewController.self),
            bundle: Bundle(for: self))
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    public override func rewrite(method: String, parameters: [String : Any]) -> Bool {
        
        if method == "roomTitleView:recognizeTapGesture" {            
            DispatchQueue.main.async {
                self.roomTitleView(parameters["titleView"] as? RoomTitleView,
                                   recognizeTapGesture: parameters["recognizeTapGesture"] as? UITapGestureRecognizer)
            }
            return true
        }
        return false
    }
}

extension CKRoomViewController {
    
    private func roomTitleView(_ titleView: RoomTitleView!, recognizeTapGesture tapGestureRecognizer: UITapGestureRecognizer!) {
        self.performSegue(withIdentifier: "showRoomDetails", sender: self)
    }
}
