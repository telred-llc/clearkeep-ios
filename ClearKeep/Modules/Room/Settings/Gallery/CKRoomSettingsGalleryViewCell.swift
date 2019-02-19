//
//  CKRoomSettingsGalleryViewCell.swift
//  CKGallery
//
//  Created by Hiếu Nguyễn on 1/15/19.
//  Copyright © 2019 Hiếu Nguyễn. All rights reserved.
//

import UIKit

class CKRoomSettingsGalleryViewCell: CKBaseCollectionCell {

    @IBOutlet weak var photoImage: MXKImageView!
    @IBOutlet weak var nameLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        photoImage.image = nil
        nameLabel.text = nil
    }
}
