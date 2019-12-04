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
    @IBOutlet weak var nameLabel: UILabel!
    
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
        self.joinButton.layer.masksToBounds = true
        self.joinButton.setTitleColor(.white, for: .normal)
        self.joinButton.setBackgroundImage(themeService.attrs.enableButtonBG, for: .normal)
        
        self.declineButton.setTitleColor(themeService.attrs.secondTextColor, for: .normal)

        self.view.theme.backgroundColor = themeService.attrStream{ $0.primaryBgColor }
        self.descriptionLabel.theme.textColor = themeService.attrStream{ $0.primaryTextColor }
        self.nameLabel.theme.textColor = themeService.attrStream { $0.navBarTintColor }
        
        self.photoView.setImageURI("", withType: "", andImageOrientation: .up, previewImage: themeService.attrs.joinRoomImage, mediaManager: nil)
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
        case self.declineButton:
            self.onDeclining()
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
    
    public func showIt(_ value: Bool, roomDataSource: MXKRoomDataSource!, previewData: RoomPreviewData?) {
        
        self.view.isHidden = !value        
       
        self.descriptionLabel.text = CKLocalization.string(byKey: "invited_default")
        var inviter: String = CKLocalization.string(byKey: "invited_unknow")
        
        if let ds = roomDataSource, value == true {
            self.photoView?.setImageURI(
                ds.room?.summary?.avatar,
                withType: nil,
                andImageOrientation: UIImageOrientation.up,
                previewImage: themeService.attrs.joinRoomImage,
                mediaManager: ds.mxSession.mediaManager)
            
            //-- binding data inviter
            let inviters = ds.roomState.members.members.filter { $0.membership == .join }
            
            inviter = inviters.first?.displayname ?? (inviters.first?.originUserId ?? CKLocalization.string(byKey: "invited_unknow"))
            self.descriptionLabel.text = CKLocalization.string(byKey: "invited_room")
            self.nameLabel.text = inviter
        }
    }
}
