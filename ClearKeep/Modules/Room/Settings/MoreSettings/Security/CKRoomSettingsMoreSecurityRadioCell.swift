//
//  CKRoomSettingsMoreSecurityRadioCell.swift
//  Riot
//
//  Created by Sinbad Flyce on 2/20/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKRoomSettingsMoreSecurityRadioCell: CKRoomBaseCell {
    
    // MARK: - OUTLET
    
    @IBOutlet weak var titleLable: UILabel!
    
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
                self.titleLable.attributedText = attrString
            }
        }
        
        get {
            return titleLable.attributedText?.string
        }
    }
    
    // MARK: - OVERRIDE
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.titleLable.textColor = CKColor.Text.black
        self.titleLable.font = UIFont.systemFont(ofSize: 16)
    }
    
    // MARK: - PRIVATE
    
    // MARK: - PUBLIC
}
