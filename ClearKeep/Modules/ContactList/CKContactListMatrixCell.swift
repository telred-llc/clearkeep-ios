//
//  CKContactListMatrixCell.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/28/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKContactListMatrixCell: CKContactListBaseCell {
    
    // MARK: - OUTLET
    @IBOutlet weak var photoView: MXKImageView!
    @IBOutlet weak var displayNameLabel: UILabel!

    // MARK: - OVERRIDE
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.displayNameLabel.backgroundColor = UIColor.clear
        
        self.photoView.defaultBackgroundColor = UIColor.clear
        self.photoView.layer.cornerRadius = (self.photoView.bounds.height) / 2
        self.photoView.clipsToBounds = true
        self.photoView.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin]
        self.photoView.contentMode = UIView.ContentMode.scaleAspectFill
    }
    
    // MARK: - PUBLIC
    func setMxAvatarUrl(_ url: String, inSession session: MXSession!) {
        if let avtURL = session.matrixRestClient.url(ofContent: url) {
            self.photoView.enableInMemoryCache = true
            self.photoView.setImageURL(
                avtURL, withType: nil,
                andImageOrientation: UIImageOrientation.up,
                previewImage: nil)
            
        } else {
            self.photoView.image = AvatarGenerator.generateAvatar(forText: self.displayNameLabel.text)
        }
    }
}
