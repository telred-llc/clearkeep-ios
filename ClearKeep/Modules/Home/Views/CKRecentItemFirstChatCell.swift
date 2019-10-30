//
//  CKRecentItemFirstChatCell.swift
//  Riot
//
//  Created by Sinbad Flyce on 2/15/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKRecentItemFirstChatCell: CKBaseCell {
    
    // MARK: - OUTLE
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var startChatButton: UIButton!
    
    // MARK: - PROPERTY
    
    internal var startChattingHanlder: (() -> Void)?
    
    // MARK: - OVERRIDE
    
    let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()

        // round button
        self.startChatButton.layer.cornerRadius = 10
        self.startChatButton.layer.borderWidth = 0
        self.startChatButton.setTitleColor(UIColor.white, for: .normal)
        
        // add action
        self.startChatButton.addTarget(self, action: #selector(onStartChatting(_:)), for: .touchUpInside)
        
        themeService.attrsStream.asObservable().subscribe { (theme) in
            let image: UIImage = themeService.type == ThemeType.light ? #imageLiteral(resourceName: "btn_start_room_light") : #imageLiteral(resourceName: "btn_start_room_dark")
            self.startChatButton.setBackgroundImage(image, for: .normal)
            self.titleLabel.textColor = theme.element?.hintText
            self.contentView.backgroundColor = theme.element?.cellPrimaryBgColor
        }.disposed(by: disposeBag)
    }
    
    // MARK: - ACTIO
    @objc func onStartChatting(_ sender: Any) {
        self.startChattingHanlder?()
    }
}
