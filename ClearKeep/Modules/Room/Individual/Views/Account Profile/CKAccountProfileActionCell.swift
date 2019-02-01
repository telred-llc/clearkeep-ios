//
//  CKAccountProfileActionCell.swift
//  Riot
//
//  Created by Hiếu Nguyễn on 1/23/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

class CKAccountProfileActionCell: CKAccountProfileBaseCell {

    // MARK: - OUTLET
    
    @IBOutlet weak var settingButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    
    
    // MARK: - PROPERTY
    
    /**
     MessageHandler
     */
    internal var settingHandler: (() -> Void)?
    
    /**
     CallHandler
     */
    internal var editHandler: (() -> Void)?
    
    
    // MARK: - OVERRIDE
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.settingButton.addTarget(self, action: #selector(onClickedSettingButton(_:)), for: .touchUpInside)
        self.editButton.addTarget(self, action: #selector(onClickedEditButton(_:)), for: .touchUpInside)
    }
    
    // MARK: - ACTION
    
    @objc func onClickedSettingButton(_ sender: Any) {
        settingHandler?()
    }
    
    @objc func onClickedEditButton(_ sender: Any) {
        editHandler?()
    }
}
