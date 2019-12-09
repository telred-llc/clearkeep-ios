//
//  CKCallHistoryCell.swift
//  Riot
//
//  Created by ReasonLeveing on 11/20/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

class CKCallHistoryCell: CKBaseCell {

    @IBOutlet weak var avatarImageView: MXKImageView!
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var datetimeLabel: UILabel!
    @IBOutlet weak var videoButton: UIButton!
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var statusView: UIView!
    
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
    
    
    var callAudioHander: (() -> Void)?
    
    var callVideoHander: (() -> Void)?
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        selectionStyle = .none
        
        datetimeLabel.theme.textColor = themeService.attrStream{ $0.primaryTextColor }

        callButton.setImage(#imageLiteral(resourceName: "call_voip_log").withRenderingMode(.alwaysTemplate), for: .normal)
        callButton.theme.tintColor = themeService.attrStream{ $0.primaryTextColor }
        
        videoButton.setImage(#imageLiteral(resourceName: "call_video_log").withRenderingMode(.alwaysTemplate), for: .normal)
        videoButton.theme.tintColor = themeService.attrStream{ $0.primaryTextColor }
    }
    
    @IBAction func actionCallVideo(_ sender: Any) {
         callVideoHander?()
    }
    
    @IBAction func actionCallAudio(_ sender: Any) {
        callAudioHander?()
    }
    
    
    func bindingData(model: CallHistoryModel) {
        
        if model.room.summary == nil { return }
        
        let previewImage = AvatarGenerator.generateAvatar(forText: model.room.summary.displayname ?? "A")

        avatarImageView?.setImageURI(model.room.summary.avatar,
                                   withType: nil,
                                   andImageOrientation: .up,
                                   toFitViewSize: avatarImageView.frame.size,
                                   with: MXThumbnailingMethodCrop,
                                   previewImage: previewImage,
                                   mediaManager: model.room.summary.mxSession.mediaManager)
        
        displayNameLabel.text = model.room.summary.displayname
        
        let eventFormat =  EventFormatter(matrixSession: model.room.mxSession)
        let datetime = eventFormat?.dateString(from: model.event, withTime: true)
        datetimeLabel.text = datetime ?? ""
        
        // bindingTheme
        if model.isMissCall {
            displayNameLabel.textColor = .red
        } else {
            displayNameLabel.theme.textColor = themeService.attrStream{ $0.primaryTextColor }
        }
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        avatarImageView.cornerRadius = self.avatarImageView.bounds.width / 2
        avatarImageView.layer.masksToBounds = true
        
        statusView.layer.cornerRadius = self.statusView.bounds.height / 2
        statusView.layer.borderColor = UIColor.white.cgColor
        statusView.layer.borderWidth = 1
    }
}


extension CKCallHistoryCell {
    
    override func prepareForReuse() {
        super.prepareForReuse()
        status = 0
        displayNameLabel.text = ""
        datetimeLabel.text = ""
    }
}
