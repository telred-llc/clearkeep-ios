//
//  CKRoomDirectCreatingActionCell.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/21/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKRoomDirectCreatingActionCell: CKRoomCreatingBaseCell {
    
    // MARK: - OUTLET

    @IBOutlet weak var newGroupButton: UIButton!
    @IBOutlet weak var newCallButton: UIButton!
    
    // MARK: - PROPERTY

    /**
     newGroupHandler
     */
    internal var newGroupHandler: (() -> Void)?
    
    /**
     newCallHandler
     */
    internal var newCallHandler: (() -> Void)?
    
    // MARK: - OVERRIDE

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.newGroupButton.addTarget(self, action: #selector(onClickedNewGroupButton(_:)), for: .touchUpInside)
        self.newCallButton.addTarget(self, action: #selector(onClickedNewCallButton(_:)), for: .touchUpInside)
    }
    
    // MARK: - ACTION
    
    @objc func onClickedNewGroupButton(_ sender: Any) {
        newGroupHandler?()
    }
    
    @objc func onClickedNewCallButton(_ sender: Any) {
        newCallHandler?()
    }

}
