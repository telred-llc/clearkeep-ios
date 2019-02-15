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
        if let lastEvent = roomCellData?.lastEvent, CKMessageContentManagement.shouldHideMessage(from: lastEvent) { // CK-34: Remove unnecessary chat content
            if let lastMessageLabel = lastMessageLabel {
                contentStackView.removeArrangedSubview(lastMessageLabel)
            }
        } else {
            if let lastMessage = roomCellData?.lastEventTextMessage {
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
        }
        
        // lastMessageEncrypted
        
        guard let rcd = roomCellData else {
            encryptedIconImage.isHidden = true
            return
        }
        
        if rcd.notificationCount > 0 || rcd.hasUnread {
            encryptedIconImage.image = UIImage(named: "ic_cell_badge")
            encryptedIconImage.isHidden = false
        } else {
            encryptedIconImage.image = UIImage(named: "ic_key_encrypted")
            encryptedIconImage.isHidden = (rcd.roomSummary.isEncrypted != true)
        }
        
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
                avatarImage.setImageURI(
                    avatarUrl,
                    withType: nil,
                    andImageOrientation: UIImageOrientation.up,
                    previewImage: defaultAvatar,
                    mediaManager: roomCellData?.roomSummary?.mxSession?.mediaManager)

            } else {
                avatarImage.image = defaultAvatar
            }
        } else {
            avatarImage.image = nil
        }
        
        // hideActivityIndicator
        avatarImage.hideActivityIndicator = true

        // style
        avatarImage.cornerRadius = avatarImage.frame.size.width / 2
        avatarImage.clipsToBounds = true
    }
}
