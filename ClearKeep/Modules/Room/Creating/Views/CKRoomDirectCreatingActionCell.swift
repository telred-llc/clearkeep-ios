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
        
        self.newGroupButton.backgroundColor = CKColor.Background.tableView
        self.newCallButton.backgroundColor = CKColor.Background.tableView
        
        self.newGroupButton.layer.cornerRadius = (self.newGroupButton.bounds.height) / 2
        self.newGroupButton.layer.borderColor = UIColor.black.cgColor
        self.newGroupButton.layer.borderWidth = 1
        self.newGroupButton.clipsToBounds = true
        self.newGroupButton.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin]
        self.newGroupButton.contentMode = UIView.ContentMode.scaleAspectFill
        
        self.newCallButton.layer.cornerRadius = (self.newCallButton.bounds.height) / 2
        self.newCallButton.layer.borderColor = UIColor.black.cgColor
        self.newCallButton.layer.borderWidth = 1
        self.newCallButton.clipsToBounds = true
        self.newCallButton.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin]
        self.newCallButton.contentMode = UIView.ContentMode.scaleAspectFill

    }
    
    // MARK: - ACTION
    
    @objc func onClickedNewGroupButton(_ sender: Any) {
        newGroupHandler?()
    }
    
    @objc func onClickedNewCallButton(_ sender: Any) {
        newCallHandler?()
    }

}
