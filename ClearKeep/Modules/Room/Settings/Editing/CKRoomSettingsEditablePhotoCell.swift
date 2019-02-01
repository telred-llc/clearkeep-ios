//
//  CKRoomSettingsEdiablePhotoCell.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/16/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKRoomSettingsEditablePhotoCell: CKRoomSettingsBaseCell {
    
    // MARK: - OUTLET
    
    @IBOutlet weak var photoView: MXKImageView!
    
    // MARK: - OVERRIDE
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.photoView.backgroundColor = UIColor.clear
        self.photoView.defaultBackgroundColor = UIColor.clear
    }
    
    // MARK: - PUBLIC
    
    public func setAvatarImageUrl(urlString: String, previewImage: UIImage?)  {
        photoView.enableInMemoryCache = true
        photoView.setImageURL(
            urlString, withType: nil,
            andImageOrientation: UIImageOrientation.up,
            previewImage: previewImage)
    }
    
    public func setImage(image: UIImage?)  {
        photoView.image = image
    }

}
