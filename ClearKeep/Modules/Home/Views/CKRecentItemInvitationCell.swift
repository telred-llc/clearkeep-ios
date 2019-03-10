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
            avatarImage.setImageURI(
                roomCellData?.roomSummary.avatar,
                withType: nil,
                andImageOrientation: UIImageOrientation.up,
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
    }
    
    func updateUI() {
        // setup decline button
        declineButton.borderWidth = 0.5
        declineButton.borderColor = UIColor.lightGray.withAlphaComponent(0.7)
        declineButton.cornerRadius = 2
        declineButton.setTitleColor(CKColor.Text.darkGray, for: .normal)
        declineButton.backgroundColor = UIColor.white
        
        // setup join button
        joinButton.setTitleColor(UIColor.white, for: .normal)
        joinButton.cornerRadius = 2
        
        // add gradient to joint button
        self.addGradient(to: joinButton)
        
        // setup avatar
        self.setupAvatar()
    }
    
    static func height(for cellData: MXKCellData!, withMaximumWidth maxWidth: CGFloat) -> CGFloat {
        return CKLayoutSize.Table.row70px
    }

}
