//
//  CkAvatarTopView.swift
//  Riot
//
//  Created by Hiếu Nguyễn on 12/29/18.
//  Copyright © 2018 matrix.org. All rights reserved.
//

import UIKit

class CkAvatarTopView: MXKView {

    @IBOutlet weak var imgAvatar: MXKImageView!
    @IBOutlet weak var imgStatus: UIView!

    class func instance() -> CkAvatarTopView? {
        return UINib.init(
            nibName: "CkAvatarTopView",
            bundle: nil).instantiate(
                withOwner: nil,
                options: nil).first as? CkAvatarTopView
    }
    
    override func awakeFromNib() {
        imgAvatar.layer.cornerRadius = (self.imgAvatar.bounds.width) / 2
        imgAvatar.clipsToBounds = true
        imgAvatar.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin]
        imgAvatar.contentMode = UIView.ContentMode.scaleAspectFill
        
        imgStatus.layer.cornerRadius = (self.imgStatus.bounds.width) / 2
        imgStatus.layer.borderWidth = 1
        imgStatus.layer.borderColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    }
    
    func setAvatarImageUrl(urlString: String!, previewImage: UIImage?)  {
        imgAvatar.enableInMemoryCache = true
        imgAvatar.setImageURI(
            urlString,
            withType: nil,
            andImageOrientation: UIImageOrientation.up,
            previewImage: previewImage,
            mediaManager: nil)
    }
    
    func setAvatarUri(_ uri: String!, userId: String, session: MXSession!) {
        
        let previewImage = AvatarGenerator.generateAvatar(forText: userId)
        
        imgAvatar.enableInMemoryCache = true        
        imgAvatar.setImageURI(uri,
                    withType: nil,
                    andImageOrientation: UIImageOrientation.up,
                    toFitViewSize: imgAvatar.frame.size,
                    with: MXThumbnailingMethodCrop,
                    previewImage: previewImage,
                    mediaManager: session.mediaManager)
    }
    
    func setImage(image: UIImage?)  {
        imgAvatar.image = image
    }
    
    func setStatus(online: Bool)  {
        if online == true {
            imgStatus.backgroundColor = CKColor.Misc.primaryGreenColor
        } else {
            imgStatus.backgroundColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
        }
    }
}
