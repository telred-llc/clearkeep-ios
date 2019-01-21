//
//  CKRoomInputToolbarView.swift
//  Riot
//
//  Created by Pham Hoa on 1/18/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

class CKRoomInputToolbarView: MXKRoomInputToolbarViewWithHPGrowingText {
    
    @IBOutlet weak var mainToolbarMinHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var mainToolbarView: UIView!

    override class func nib() -> UINib? {
        return UINib.init(
            nibName: String(describing: CKRoomInputToolbarView.self),
            bundle: Bundle(for: self))
    }

    class func initRoomInputToolbarView() -> CKRoomInputToolbarView {
        if self.nib() != nil {
            return self.nib()?.instantiate(withOwner: nil, options: nil).first as! CKRoomInputToolbarView
        } else {
            return super.init() as! CKRoomInputToolbarView
        }
    }
}

extension CKRoomInputToolbarView: MediaPickerViewControllerDelegate {
    func mediaPickerController(_ mediaPickerController: MediaPickerViewController!, didSelectImage imageData: Data!, withMimeType mimetype: String!, isPhotoLibraryAsset: Bool) {
        
    }
    
    func mediaPickerController(_ mediaPickerController: MediaPickerViewController!, didSelectVideo videoURL: URL!) {
        
    }
}
