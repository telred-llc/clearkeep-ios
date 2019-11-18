//
//  CKContactListLocalCell.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/28/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation


final class CKContactListLocalCell: CKContactListBaseCell {
    
    // MARK: - OUTLET
    
    @IBOutlet weak var photoView: UIImageView!
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var inviteButton: UIButton!
    
    // MARK: - OVERRIDE
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.displayNameLabel.backgroundColor = UIColor.clear
        self.emailLabel.backgroundColor = UIColor.clear

        self.displayNameLabel.theme.textColor = themeService.attrStream{ $0.primaryTextColor }
        self.emailLabel.theme.textColor = themeService.attrStream{ $0.secondTextColor }
        themeService.rx
            .bind({ $0.acceptButtonBg }, to: self.inviteButton.rx.backgroundImage())
            .disposed(by: DisposeBag())
    }
    
    // MARK: - PUBLIC
    
    func updateDisplay() {
        self.layoutIfNeeded()
        self.photoView.backgroundColor = UIColor.clear
        self.photoView.layer.cornerRadius = (self.photoView.bounds.height) / 2
        self.photoView.clipsToBounds = true
        self.photoView.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin]
        self.photoView.contentMode = UIView.ContentMode.scaleAspectFill
    }
    
    func setup(_ contact: MXKContact!) {
        
        guard let contact = contact else {
            return
        }
        
        // display name
        self.displayNameLabel.text = contact.displayName
        
        // mx email
        if let email = contact.emailAddresses.first as? MXKEmail {
            
            // display email string
            self.emailLabel.text = email.emailAddress
            
            // if display name is nill, then cut-off email name
            if self.displayNameLabel.text == nil || self.displayNameLabel.text?.count == 0 {
                
                // display cutted-off email name
                self.displayNameLabel.text = email.emailAddress
            }
            
            // avatar
            self.photoView.image = AvatarGenerator.generateAvatar(forText: self.displayNameLabel.text)
        }
    }
}
