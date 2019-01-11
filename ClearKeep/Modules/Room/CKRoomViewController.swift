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
    
    private func execute(execute: @escaping () -> Void) {
        DispatchQueue.main.async {
            execute()
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    public override func rewrite(method: String, parameters: [String : Any]) -> Bool {
        switch method {

        // recognizeTapGesture
        case "roomTitleView:recognizeTapGesture":
            self.execute {
                self.override_roomTitleView(
                    parameters["titleView"] as? RoomTitleView,
                    recognizeTapGesture: parameters["recognizeTapGesture"] as? UITapGestureRecognizer)
            }
        
        // prepareForSegue
        case "prepareForSegue:sender":
            self.execute {
                self.override_prepare(
                    for: parameters["segue"] as! UIStoryboardSegue,
                    sender: parameters["sender"])
            }
        default:
            return false
        }
        return true
    }
}

extension CKRoomViewController {
    
    private func override_roomTitleView(_ titleView: RoomTitleView!, recognizeTapGesture tapGestureRecognizer: UITapGestureRecognizer!) {
        self.performSegue(withIdentifier: "showRoomDetails", sender: self)
    }
    
    private func override_prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let roomSettingsVC = segue.destination as? CKRoomSettingsViewController {
            self.dismissKeyboard()
            roomSettingsVC.initWith(
                self.roomDataSource.mxSession,
                andRoomId: self.roomDataSource.roomId)
        }
    }
}
