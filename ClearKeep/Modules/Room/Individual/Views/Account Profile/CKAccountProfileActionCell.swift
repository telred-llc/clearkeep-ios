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
    
    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    
    
    // MARK: - PROPERTY
    
    /**
     MessageHandler
     */
    internal var MessageHandler: (() -> Void)?
    
    /**
     CallHandler
     */
    internal var EditHandler: (() -> Void)?
    
    
    // MARK: - OVERRIDE
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.messageButton.addTarget(self, action: #selector(onClickedMessageButton(_:)), for: .touchUpInside)
        self.editButton.addTarget(self, action: #selector(onClickedCallButton(_:)), for: .touchUpInside)
    }
    
    // MARK: - ACTION
    
    @objc func onClickedMessageButton(_ sender: Any) {
        MessageHandler?()
    }
    
    @objc func onClickedCallButton(_ sender: Any) {
        EditHandler?()
    }
    
    
    
    
}
