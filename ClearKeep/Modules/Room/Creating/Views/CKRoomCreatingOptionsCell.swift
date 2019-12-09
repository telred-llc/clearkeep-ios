//
//  CKRoomCreatingOptionsCell.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/19/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKRoomCreatingOptionsCell: CKRoomCreatingBaseCell {
    
    // MARK: - OUTLET

    @IBOutlet weak var checkmarkImageview: UIImageView!
    @IBOutlet weak var contentLabel: UILabel!
    
    // MARK: - PROPERTY
    
    
    private var __isChecking: Bool = false
    
    private var disposeBag = DisposeBag()

    /**
     isChecked true/false
     */
    internal var isChecked: Bool {
        get {
            return __isChecking
        }
        set {
            __isChecking = newValue
            
            if __isChecking {
                
                themeService.attrsStream.subscribe { (theme) in
                    self.checkmarkImageview.image = theme.element?.checkBoxImage
                }.disposed(by: self.disposeBag)
                
            } else {
                self.checkmarkImageview.image = #imageLiteral(resourceName: "ic_check_no")
            }
            
        }
    }
    /**
     edittingChangedHandler
     */
    internal var valueChangedHandler: ((Bool) -> Void)?

    // MARK: - OVERRIDE
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .clear
        self.contentLabel.text = CKLocalization.string(byKey: "create_room_option_anyone_join")
        self.contentLabel.theme.textColor = themeService.attrStream{ $0.primaryTextColor }
    }
    
    @IBAction func clickCheckmark(_ sender: Any) {
        self.isChecked = !self.isChecked
        valueChangedHandler?(self.isChecked)
    }

}
