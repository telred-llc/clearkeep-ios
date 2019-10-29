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
    @IBOutlet weak var notifyImage: UIImageView!
    @IBOutlet weak var contentStackView: UIStackView!
    @IBOutlet weak var declineButton: UIButton!
    @IBOutlet weak var joinButton: UIButton!
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var statusView: UIView!
    

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
    var lastMessageLabel: UILabel?
    
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
    
    // MARK: - OVERRIDE
    
    override func awakeFromNib() {
        super.awakeFromNib()
                
        self.declineButton.addTarget(self, action: #selector(declineOnPress(_:)) , for: .touchUpInside)
        self.joinButton.addTarget(self, action: #selector(joinOnPress(_:)) , for: .touchUpInside)
        self.contentView.theme.backgroundColor = themeService.attrStream{ $0.cellPrimaryBgColor }
        
        self.statusView.layer.cornerRadius = self.statusView.bounds.height / 2
        self.statusView.layer.borderColor = UIColor.white.cgColor
        self.statusView.layer.borderWidth = 2
        
        status = 0 // set status default always offline
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.roomCellData = nil
        self.joinOnPressHandler = nil
        self.declineOnPressHandler = nil
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
            
            // -- fixbug CK 318: fill avatar (remove black background of avatar)
            avatarImage.setImageURI(roomCellData?.roomSummary.avatar,
                                    withType: nil,
                                    andImageOrientation: UIImageOrientation.up,
                                    toFitViewSize: avatarImage.frame.size,
                                    with: MXThumbnailingMethodCrop,
                                    previewImage: defaultAvatar,
                                    mediaManager: roomCellData?.roomSummary.mxSession.mediaManager)
            
        } else {
            avatarImage.image = nil
        }
        
        // hideActivityIndicator
        avatarImage.hideActivityIndicator = true

        // style
        self.avatarImage.cornerRadius = avatarImage.frame.size.width / 2
        self.avatarImage.clipsToBounds = true
    }
    
    /**
     Add gradient to view
     */
    func addGradient(to view: UIView) {
        let gradientLayer = CAGradientLayer()
        
        let startColor = UIColor.init(red: 22/255, green: 168/255, blue: 197/255, alpha: 1)
        let endColor = UIColor.init(red: 46/255, green: 176/255, blue: 164/255, alpha: 1)
        
        gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
        gradientLayer.startPoint = CGPoint.zero
        gradientLayer.endPoint = CGPoint.init(x: 0, y: 1)
        gradientLayer.frame = view.bounds
        if let topLayer = view.layer.sublayers?.first, topLayer is CAGradientLayer
        {
            topLayer.removeFromSuperlayer()
        }
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
}

extension CKRecentItemInvitationCell: MXKCellRendering {
    func render(_ cellData: MXKCellData!) {
        roomCellData = cellData as? MXKRecentCellDataStoring
        roomNameLabel.text = roomCellData?.roomSummary.displayname
        lblTime.text = roomCellData?.lastEventDate
        
        // last message
        guard let lastMessage = roomCellData?.roomSummary.lastMessageString else {
            self.lblDescription.text = ""
            return
        }
        if let user = roomCellData?.lastEvent.wireContent["displayname"] as? String, user.count > 0 {
            let start = lastMessage.index(lastMessage.startIndex, offsetBy: lastMessage.count - user.count)
            let end = lastMessage.index(lastMessage.startIndex, offsetBy: lastMessage.count)
            var message = lastMessage
            message.replaceSubrange(start..<end, with: "you")
            self.lblDescription.text = message
        }
    }

    func updateUI() {

        // setup avatar
        self.setupAvatar()
    }
    
    static func height(for cellData: MXKCellData!, withMaximumWidth maxWidth: CGFloat) -> CGFloat {
        return CKLayoutSize.Table.row70px
    }

}
