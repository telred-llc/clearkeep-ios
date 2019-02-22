//
//  CKContactListMatrixCell.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/28/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKContactListMatrixCell: CKContactListBaseCell {
    
    // MARK: - OUTLET
    @IBOutlet weak var photoView: MXKImageView!
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var statusView: UIView!

    // MARK: - OVERRIDE
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.displayNameLabel.backgroundColor = UIColor.clear
        
        self.photoView.defaultBackgroundColor = UIColor.clear
        self.photoView.layer.cornerRadius = (self.photoView.bounds.height) / 2
        self.photoView.clipsToBounds = true
        self.photoView.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin]
        self.photoView.contentMode = UIView.ContentMode.scaleAspectFill
        
        self.statusView.layer.cornerRadius = self.statusView.bounds.height / 2
        self.statusView.layer.borderColor = UIColor.white.cgColor
        self.statusView.layer.borderWidth = 2
    }
    
    // MARK: - PRIVATE
    
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
    
    // MARK: - OVERRIDE
    
    override func getMXKImageView() -> MXKImageView! {
        return self.photoView
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.status = 0
    }
    
    // MARK: - PUBLIC
}
