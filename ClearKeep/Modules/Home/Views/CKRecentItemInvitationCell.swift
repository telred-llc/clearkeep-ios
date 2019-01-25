//
//  CKRecentItemInvitationCell.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/24/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKRecentItemInvitationCell: MXKTableViewCell {
    
    // MARK: - OUTLET
    
    @IBOutlet weak var avatarImage: MXKImageView!
    @IBOutlet weak var roomNameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var notifyImage: UIImageView!
    @IBOutlet weak var contentStackView: UIStackView!
    @IBOutlet weak var declineButton: UIButton!
    @IBOutlet weak var joinButton: UIButton!
    

    // MARK: - PROPERTY
    
    internal var declineOnPressHandler: (() -> Void)?
    internal var joinOnPressHandler: (() -> Void)?
    
    /**
     Room cell-data
     */
    private var roomCellData: MXKRecentCellDataStoring?
    
    /**
     Last message label
     */
    private var lastMessageLabel: UILabel?
    
    // MARK: - OVERRIDE
    
    override func awakeFromNib() {
        super.awakeFromNib()
                
        self.declineButton.addTarget(self, action: #selector(declineOnPress(_:)) , for: .touchUpInside)
        self.joinButton.addTarget(self, action: #selector(joinOnPress(_:)) , for: .touchUpInside)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.roomCellData = nil
    }
    
    // MARK: - ACTION
    
    @objc func declineOnPress(_ sender: Any) {
        self.declineOnPressHandler?()
    }

    @objc func joinOnPress(_ sender: Any) {
        self.joinOnPressHandler?()
    }

    // MARK: - PRIVATE
    
    /**
     Setup room avatar
     */
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
        self.avatarImage.cornerRadius = avatarImage.frame.size.width / 2
        self.avatarImage.clipsToBounds = true
    }
}

extension CKRecentItemInvitationCell: MXKCellRendering {
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
        
        // setup avatar
        self.setupAvatar()
    }
    
    static func height(for cellData: MXKCellData!, withMaximumWidth maxWidth: CGFloat) -> CGFloat {
        return CKLayoutSize.Table.row70px
    }

}
