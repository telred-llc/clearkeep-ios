//
//  CKRoomInvitationView.swift
//  Riot
//
//  Created by Sinbad Flyce on 2/27/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

protocol CKRoomInvitationControllerDeletate: class {
    func invitationDidSelectJoin()
    func invitationDidSelectDecline()
}

@objc class CKRoomInvitationController: NSObject {
    
    // MARK: - OUTLET
    
    @IBOutlet weak var view: UIView!
    @IBOutlet weak var photoView: MXKImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var joinButton: UIButton!
    @IBOutlet weak var declineButton: UIButton!
    
    // MARK: - PROPERTY
    
    weak var delegate: CKRoomInvitationControllerDeletate?
    
    // MARK: - OVERRIDE
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.photoView.defaultBackgroundColor = UIColor.clear
        self.photoView.layer.cornerRadius = (self.photoView.bounds.height) / 2
        self.photoView.clipsToBounds = true
        self.photoView.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin]
        self.photoView.contentMode = UIView.ContentMode.scaleAspectFill
        
        self.joinButton.layer.cornerRadius = 4
        self.joinButton.layer.borderWidth = 1
        self.joinButton.layer.borderColor = CKColor.Misc.primaryGreenColor.cgColor
        self.joinButton.setTitleColor(UIColor.white, for: .normal)
        
        self.joinButton.applyGradient(colours: [#colorLiteral(red: 0.2392156863, green: 0.737254902, blue: 0.6823529412, alpha: 1), #colorLiteral(red: 0.01568627451, green: 0.7137254902, blue: 0.8156862745, alpha: 1)])
        
        self.declineButton.layer.cornerRadius = 4
        self.declineButton.layer.borderWidth = 1
        self.declineButton.layer.borderColor = CKColor.Misc.primaryGreenColor.cgColor
        self.declineButton.setTitleColor(CKColor.Misc.primaryGreenColor, for: .normal)
    }
    
    
    // MARK: - ACTION
    
    // MARK: - PRIVATE
    
    private func onJoining() {
        self.delegate?.invitationDidSelectJoin()
    }
    
    private func onDeclining() {
        self.delegate?.invitationDidSelectDecline()
    }
    
    // MARK: - PUBLIC
    
    public func clickedOnButton(_ sender: UIButton!) {
        
        switch sender {
        case self.joinButton:
            self.onJoining()
            break
        case self.declineButton:
            self.onDeclining()
            break
        default:
            break
        }
        
    }
    
    public func update() {
        self.joinButton.applyGradient(colours: [#colorLiteral(red: 0.2392156863, green: 0.737254902, blue: 0.6823529412, alpha: 1), #colorLiteral(red: 0.01568627451, green: 0.7137254902, blue: 0.8156862745, alpha: 1)])
        
        self.photoView.defaultBackgroundColor = UIColor.clear
        self.photoView.layer.cornerRadius = (self.photoView.bounds.height) / 2
        self.photoView.clipsToBounds = true
        self.photoView.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin]
        self.photoView.contentMode = UIView.ContentMode.scaleAspectFill
    }
    
    public func showIt(_ value: Bool, roomDataSource: MXKRoomDataSource!) {
        
        self.view.isHidden = !value        
        let title = "You have been invited you to this room, join to chat?"
        
        if let ds = roomDataSource, value == true {
            self.descriptionLabel.text = title
            
            self.photoView?.setImageURI(
                ds.room?.summary?.avatar,
                withType: nil,
                andImageOrientation: UIImageOrientation.up,
                previewImage: AvatarGenerator.generateAvatar(forText: ds.room?.summary?.displayname),
                mediaManager: ds.mxSession.mediaManager)

        }
    }
}
