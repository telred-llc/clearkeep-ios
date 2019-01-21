//
//  CKRoomCreatingOptionsCell.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/19/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKRoomCreatingOptionsCell: CKRoomCreatingBaseCell {
    
    // MARK: - OUTLET

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var desciptpionLabel: UILabel!
    @IBOutlet weak var optionSwitch: UISwitch!
    
    // MARK: - PROPERTY
    
    /**
     edittingChangedHandler
     */
    internal var valueChangedHandler: ((Bool) -> Void)?

    // MARK: - OVERRIDE
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.titleLabel.superview?.backgroundColor = UIColor.clear
        self.optionSwitch.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
    }
    
    @objc func switchChanged(sender: UISwitch) {
        valueChangedHandler?(sender.isOn)
    }

}
