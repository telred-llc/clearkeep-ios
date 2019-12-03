//
//  CKRoomDirectCreatingActionCell.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/21/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKRoomDirectCreatingActionCell: CKRoomCreatingBaseCell {
    
    @IBOutlet weak var newCallLabel: UILabel!
    @IBOutlet weak var newCallImageView: UIImageView!
    
    @IBOutlet weak var newRoomLabel: UILabel!
    @IBOutlet weak var newRoomImageView: UIImageView!
    /**
     newGroupHandler
     */
    internal var newGroupHandler: (() -> Void)?
    
    /**
     newCallHandler
     */
    internal var newCallHandler: (() -> Void)?
    
    // MARK: - OVERRIDE
    
    private let disposeBag = DisposeBag()

    override func awakeFromNib() {
        super.awakeFromNib()
        
        themeService.attrsStream.asObservable().subscribe { (theme) in
            
            self.newCallLabel.textColor = theme.element?.navBarTintColor
            self.newRoomLabel.textColor = theme.element?.navBarTintColor
            
            let lightTheme = themeService.type == ThemeType.light
            self.newRoomImageView.image = lightTheme ? #imageLiteral(resourceName: "ic_new_room_ellipse") : #imageLiteral(resourceName: "ic_new_room_ellipse_dark")
            self.newCallImageView.image = lightTheme ? #imageLiteral(resourceName: "ic_new_call_ellipse") : #imageLiteral(resourceName: "ic_new_call_ellipse_dark")
        }.disposed(by: disposeBag)
    }
    
    // MARK: - ACTION
    
    @IBAction func onClickNewGroup(_ sender: Any) {
        newGroupHandler?()
    }
    
    @IBAction func onClickNewCall(_ sender: Any) {
         newCallHandler?()
    }

}
