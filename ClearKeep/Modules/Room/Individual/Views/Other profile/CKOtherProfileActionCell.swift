//
//  CKAccountProfileActionCell.swift
//  Riot
//
//  Created by Hiếu Nguyễn on 1/23/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

class CKOtherProfileActionCell: CKAccountProfileBaseCell {
    
    // MARK: - OUTLET
    
    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var callButton: UIButton!
    
    
    // MARK: - PROPERTY
    
    /**
     MessageHandler
     */
    internal var messageHandler: (() -> Void)?
    
    /**
     CallHandler
     */
    internal var callHandler: (() -> Void)?
    
    
    // MARK: - OVERRIDE
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.messageButton.addTarget(self, action: #selector(onClickedMessageButton(_:)), for: .touchUpInside)
        self.callButton.addTarget(self, action: #selector(onClickedCallButton(_:)), for: .touchUpInside)
    }
    
    // MARK: - ACTION
    
    @objc func onClickedMessageButton(_ sender: Any) {
        messageHandler?()
    }
    
    @objc func onClickedCallButton(_ sender: Any) {
        callHandler?()
    }
    
    
    
    
}
