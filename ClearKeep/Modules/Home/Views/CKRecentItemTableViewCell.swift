//
//  CKRecentItemTableViewCell.swift
//  Riot
//
//  Created by Pham Hoa on 1/7/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

class CKRecentItemTableViewCell: MXKTableViewCell, MXKCellRendering {

    @IBOutlet weak var avatarImage: MXKImageView!
    @IBOutlet weak var roomNameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var contentStackView: UIStackView!
    @IBOutlet weak var encryptedIconImage: UIImageView!
    
    private var lastMessageLabel: UILabel?
    private var roomCellData: MXKRecentCellDataStoring?
    
    func render(_ cellData: MXKCellData!) {
        roomCellData = cellData as? MXKRecentCellDataStoring
     
        roomNameLabel.text = roomCellData?.roomSummary.displayname
        timeLabel.text = roomCellData?.lastEventDate

        // last message
        if let lastMessage = roomCellData?.roomSummary.lastMessageString {
            if lastMessageLabel == nil {
                lastMessageLabel = UILabel.init()
            }
            
            if !contentStackView.arrangedSubviews.contains(where: { $0 == lastMessageLabel }) {
                contentStackView.addArrangedSubview(lastMessageLabel!)
            }
            
            lastMessageLabel!.text = lastMessage
            lastMessageLabel!.font = CKAppTheme.mainThinAppFont(size: 14)
        } else {
            if let lastMessageLabel = lastMessageLabel {
                contentStackView.removeArrangedSubview(lastMessageLabel)
            }
        }
        
        // lastMessageEncrypted
        encryptedIconImage.isHidden = roomCellData?.roomSummary.isLastMessageEncrypted != true
        
        setupAvatar()
    }
    
    func renderedCellData() -> MXKCellData! {
        return roomCellData as? MXKCellData
    }
    
    static func height(for cellData: MXKCellData!, withMaximumWidth maxWidth: CGFloat) -> CGFloat {
        // The height is fixed
        return 70;
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        roomCellData = nil
    }
}

private extension CKRecentItemTableViewCell {
    func setupAvatar() {
        
        if let roomId = roomCellData?.roomSummary.roomId,
            let displayname = roomCellData?.roomSummary.displayname {
            let defaultAvatar = AvatarGenerator.generateAvatar(forMatrixItem: roomId, withDisplayName: displayname)
            if let avatarUrl = roomCellData?.roomSummary.avatar {
                avatarImage.enableInMemoryCache = true
                avatarImage.setImageURL(avatarUrl, withType: nil, andImageOrientation: UIImageOrientation.up, previewImage: defaultAvatar)
            } else {
                avatarImage.setImageURL("", withType: nil, andImageOrientation: UIImageOrientation.up, previewImage: defaultAvatar)
            }
        } else {
            avatarImage.setImageURL("", withType: nil, andImageOrientation: UIImageOrientation.up, previewImage: nil)
        }
        
        // style
        avatarImage.cornerRadius = avatarImage.frame.size.width / 2
        avatarImage.clipsToBounds = true
    }
}
