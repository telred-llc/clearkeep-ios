//
//  CKRoomDirectCreatingActionCell.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/21/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKRoomDirectCreatingActionCell: CKRoomCreatingBaseCell {
    
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

    }
    
    // MARK: - ACTION
    
    @IBAction func onClickNewGroup(_ sender: Any) {
        newGroupHandler?()
    }
    
    @IBAction func onClickNewCall(_ sender: Any) {
         newCallHandler?()
    }

}
