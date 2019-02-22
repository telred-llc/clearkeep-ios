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
    @IBOutlet weak var statusView: UIView!
    
    private var lastMessageLabel: UILabel?
    private var roomCellData: MXKRecentCellDataStoring?
    
    public var status: Int {
        set {
            self.statusView.tag = newValue
            if newValue > 0 {
                self.statusView.backgroundColor = CKColor.Misc.onlineColor
            } else {
                self.statusView.backgroundColor = CKColor.Misc.offlineColor
            }
        }
        
        get {
            return self.statusView.tag
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.statusView.layer.cornerRadius = self.statusView.bounds.height / 2
        self.statusView.layer.borderColor = UIColor.white.cgColor
        self.statusView.layer.borderWidth = 2
    }
    
    /**
     Rendering of direct user status
     */
    private func renderStatus(_ roomSummary: MXRoomSummary!) {
        
        // is room chat
        if (roomSummary?.isDirect ?? false) == false {
            self.statusView.isHidden = true
        } else { // is direct chat
            self.statusView.isHidden = false
        }
        
        self.status = 0
        if let directUserId = roomSummary?.room?.directUserId {
            
            if directUserId == (roomSummary?.mxSession?.myUser?.userId ?? "") {
                self.status = 0
                return
            }
            
            if let mxDirectUser = roomSummary?.mxSession?.user(
                withUserId: directUserId) {
                self.status = mxDirectUser.presence == MXPresenceOnline ? 1 : 0
            }
        }
    }
    
    /**
     Rendering of cell data
     */
    func render(_ cellData: MXKCellData!) {
        roomCellData = cellData as? MXKRecentCellDataStoring
        roomNameLabel.text = roomCellData?.roomSummary.displayname
        timeLabel.text = roomCellData?.lastEventDate
        
        // rendering of status
        self.renderStatus(roomCellData?.roomSummary)
        
        // last message
        if let lastEvent = roomCellData?.lastEvent,
            CKMessageContentManagement.shouldHideMessage(
                from: lastEvent, inRoomState: nil) { // CK-34: Remove unnecessary chat content
            if let lastMessageLabel = lastMessageLabel {
                contentStackView.removeArrangedSubview(lastMessageLabel)
                lastMessageLabel.removeFromSuperview()
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
                    lastMessageLabel.removeFromSuperview()
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
        return CKLayoutSize.Table.row70px;
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
