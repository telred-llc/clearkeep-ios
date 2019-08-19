//
//  CKBaseCell.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/28/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

class CKBaseCell: UITableViewCell {

    // MARK: - CLASS VAR
    class var className: String {
        return String(describing: self)
    }
    
    // MARK: - CLASS OVERRIDEABLE
    
    open class var identifier: String {
        return self.nibName
    }
    
    open class var nibName: String {
        return self.className
    }
    
    class var nib: UINib {
        return UINib.init(nibName: self.nibName, bundle: nil)
    }
    
    open func getMXKImageView() -> MXKImageView! {
        return nil
    }
    
    public func setAvatarUri(_ uri: String!, identifyText: String, session: MXSession!, cropped: Bool = true) {
        self.getMXKImageView()?.enableInMemoryCache = true
        
        if !cropped {
            self.getMXKImageView()?.setImageURI(uri,
                                       withType: nil,
                                       andImageOrientation: UIImageOrientation.up,
                                       previewImage: AvatarGenerator.generateAvatar(forText: identifyText),
                                       mediaManager: session.mediaManager)
        } else {
            self.getMXKImageView()?.setImageURI(uri,
                                                withType: nil,
                                                andImageOrientation: UIImageOrientation.up,
                                                toFitViewSize: self.getMXKImageView()?.frame.size ?? CGSize.zero,
                                                with: MXThumbnailingMethodCrop,
                                                previewImage: AvatarGenerator.generateAvatar(forText: identifyText),
                                                mediaManager: session.mediaManager)
        }
    }
}
