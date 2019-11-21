//
//  CKHeaderCallHistoryView.swift
//  Riot
//
//  Created by ReasonLeveing on 11/20/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

class CKHeaderCallHistoryView: UITableViewHeaderFooterView {

    @IBOutlet weak var iconCallImageView: UIImageView!
    @IBOutlet weak var callLogLabel: UILabel!
    
    static var className: String {
        return String(describing: self)
    }
    
    static var identifier: String {
        return self.nibName
    }
    
    static var nibName: String {
        return self.className
    }
    
    static var nib: UINib {
        return UINib.init(nibName: self.nibName, bundle: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.theme.backgroundColor = themeService.attrStream{ $0.tblHeaderBgColor }
        callLogLabel.text = CKLocalization.string(byKey: "call_history_title")
        callLogLabel.theme.textColor = themeService.attrStream{ $0.primaryTextColor }

        let image = #imageLiteral(resourceName: "call_log").withRenderingMode(.alwaysTemplate)
        iconCallImageView.image = image
        iconCallImageView.theme.tintColor = themeService.attrStream{ $0.primaryTextColor }
    }

}
