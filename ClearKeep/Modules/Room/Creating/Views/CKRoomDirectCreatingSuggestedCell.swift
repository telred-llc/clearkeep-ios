//
//  CKRoomDirectCreatingSuggestedCell.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/21/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKRoomDirectCreatingSuggestedCell: CKRoomCreatingBaseCell {
    @IBOutlet weak var photoView: MXKImageView!
    @IBOutlet weak var suggesteeLabel: UILabel!

    // MARK: - OVERRIDE
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.suggesteeLabel.backgroundColor = UIColor.clear
        self.suggesteeLabel.textColor = UIColor.black
        
        self.photoView.defaultBackgroundColor = UIColor.clear
        self.photoView.layer.cornerRadius = (self.photoView.bounds.height) / 2
        self.photoView.clipsToBounds = true
        self.photoView.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin]
        self.photoView.contentMode = UIView.ContentMode.scaleAspectFill
    }
    
    // MARK: - PUBLIC
    public func setAvatarImageUrl(urlString: String, previewImage: UIImage?)  {
        photoView.enableInMemoryCache = true
        photoView.setImageURL(
            urlString, withType: nil,
            andImageOrientation: UIImageOrientation.up,
            previewImage: previewImage)
    }
}
