//
//  CKRecentItemFirstChatCell.swift
//  Riot
//
//  Created by Sinbad Flyce on 2/15/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKRecentItemFirstChatCell: CKBaseCell {
    
    // MARK: - OUTLE
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var startChatButton: UIButton!
    
    // MARK: - PROPERTY
    
    internal var startChattingHanlder: (() -> Void)?
    
    // MARK: - OVERRIDE
    
    override func awakeFromNib() {
        super.awakeFromNib()

        // round button
        self.startChatButton.layer.cornerRadius = 10
        self.startChatButton.layer.borderWidth = 0
        self.startChatButton.setTitleColor(UIColor.white, for: .normal)
        
        // add action
        self.startChatButton.addTarget(self, action: #selector(onStartChatting(_:)), for: .touchUpInside)
    }
    
    // MARK: - ACTIO
    @objc func onStartChatting(_ sender: Any) {
        self.startChattingHanlder?()
    }
}
