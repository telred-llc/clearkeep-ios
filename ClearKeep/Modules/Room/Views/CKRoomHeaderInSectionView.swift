//
//  CKRoomHeaderInSectionView.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/21/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKRoomHeaderInSectionView: UIView {
    
    // MARK: - OUTLET
    @IBOutlet weak var descriptionLabel: UILabel!
    
    // MARK: - CLASSS
    
    public class func instance() -> CKRoomHeaderInSectionView? {
        return UINib(
            nibName: "CKRoomHeaderInSectionView",
            bundle: nil).instantiate(withOwner: nil, options: nil).first as? CKRoomHeaderInSectionView
    }
    
    // MARK: - PROPERTY
        
    // MARK: - OVERRIDE
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = CKColor.Background.tableView
        self.descriptionLabel.backgroundColor = UIColor.clear
    }
    
    // MARK: - PUBLIC
    
}
