//
//  CKRoomSettingsMoreRoleCell.swift
//  Riot
//
//  Created by Sinbad Flyce on 2/21/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKRoomSettingsMoreRoleCell: CKBaseCell {
    
    // MARK: - OUTLET
    @IBOutlet weak var titleLabel: UILabel!
    
    // MARK: - PROPERTY

    public var title: String? {
        set {
            if let v = newValue {
                let attrString = NSMutableAttributedString(attributedString: NSAttributedString(string: v))
                let style = NSMutableParagraphStyle()
                style.lineSpacing = 4
                attrString.addAttributes(
                    [NSAttributedStringKey.paragraphStyle : style],
                    range: NSRange(location: 0, length: v.count))
                self.titleLabel.attributedText = attrString
            }
        }
        
        get {
            return titleLabel.attributedText?.string
        }
    }
    // MARK: - OVERRIDE
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.titleLabel.textColor = CKColor.Text.black
        self.titleLabel.font = UIFont.systemFont(ofSize: 16)
    }
    
    // MARK: - PRIVATE
    
    // MARK: - PUBLIC
}
