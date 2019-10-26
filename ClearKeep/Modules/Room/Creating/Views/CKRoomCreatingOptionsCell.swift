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
    
    // MARK: - PROPERTY
    
    
    private var __isChecking: Bool = false

    /**
     isChecked true/false
     */
    internal var isChecked: Bool {
        get {
            return __isChecking
        }
        set {
            __isChecking = newValue
            
            let checkedImage = UIImage(named: "ic_check_yes")
            let unCheckedImage = UIImage(named: "ic_check_no")
            self.checkmarkImageview.image = __isChecking ? checkedImage : unCheckedImage
        }
    }
    /**
     edittingChangedHandler
     */
    internal var valueChangedHandler: ((Bool) -> Void)?

    // MARK: - OVERRIDE
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    @IBAction func clickCheckmark(_ sender: Any) {
        self.isChecked = !self.isChecked
        valueChangedHandler?(self.isChecked)
    }

}
