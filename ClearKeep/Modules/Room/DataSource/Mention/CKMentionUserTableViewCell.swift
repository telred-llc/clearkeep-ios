//
//  MentionUserTableViewCell.swift
//  Riot
//
//  Created by Pham Hoa on 1/24/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

final class CKMentionUserTableViewCell: MXKTableViewCell {
    
    @IBOutlet weak var avatarImageView: MXKImageView!
    @IBOutlet weak var usernameLabel: UILabel!

    // MARK: - Override
    
    public override class func nib() -> UINib? {
        return UINib.init(
            nibName: String(describing: CKMentionUserTableViewCell.self),
            bundle: Bundle(for: self))
    }
}
