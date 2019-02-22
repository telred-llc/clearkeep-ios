//
//  CKRoomAddingMembersCell.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/22/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKRoomAddingMembersCell: CKRoomBaseCell {

    // MARK: - OUTLET
    
    @IBOutlet weak var photoView: MXKImageView!
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var checkmarkImageView: UIImageView!
    @IBOutlet weak var statusView: UIView!
    
    // MARK: - PROPERTY
    
    /**
     An bool var to on/off checkmark
     */
    private var __isChecking: Bool = false
    
    /**
     isChecked true/false
     */
    internal var isChecked: Bool {
        get {
            return __isChecking
        }
        
        set {
            __isChecking = newValue
            self.checkmarkImageView.image = __isChecking ? UIImage(named: "ic_check_yes") : UIImage(named: "ic_check_no")
        }
    }
    
    internal func changesBy(mxContact contact: MXKContact!, inSession session: MXSession!)  {
        self.setAvatarUri(
            contact.matrixAvatarURL,
            identifyText: contact.displayName,
            session: session)
    }
    
    // MARK: - OVERRIDE
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.displayNameLabel.backgroundColor = UIColor.clear
        self.displayNameLabel.textColor = UIColor.black
        
        self.photoView.defaultBackgroundColor = UIColor.clear
        self.photoView.layer.cornerRadius = (self.photoView.bounds.height) / 2
        self.photoView.clipsToBounds = true
        self.photoView.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin]
        self.photoView.contentMode = UIView.ContentMode.scaleAspectFill
        
        self.statusView.layer.cornerRadius = self.statusView.bounds.height / 2
        self.statusView.layer.borderColor = UIColor.white.cgColor
        self.statusView.layer.borderWidth = 2
    }
    
    override func getMXKImageView() -> MXKImageView! {
        return self.photoView
    }
    
    // MARK: - PUBLIC
    
    public var status: Int {
        set {
            self.statusView.tag = newValue
            if newValue > 0 {
                self.statusView.backgroundColor = CKColor.Misc.onlineColor
            } else {
                self.statusView.backgroundColor = CKColor.Misc.offlineColor
            }
        }
        
        get {
            return self.statusView.tag
        }
    }
}
