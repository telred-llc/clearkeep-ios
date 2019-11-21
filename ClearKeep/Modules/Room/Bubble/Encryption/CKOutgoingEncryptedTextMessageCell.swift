//
//  CKOutgoingEncryptedTextMessageCell.swift
//  Riot
//
//  Created by klinh on 11/19/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

class CKOutgoingEncryptedTextMessageCell: RoomOutgoingTextMsgBubbleCell {

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    override func render(_ cellData: MXKCellData!) {
//        super.render(cellData)
        self.encryptionStatusContainerView?.isUserInteractionEnabled = false
    }

    @IBAction func decryptionStatusDidTouch(_ sender: UIButton) {
        // TO-DO
    }
}
