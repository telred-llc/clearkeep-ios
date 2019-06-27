//
//  CKRecentHeaderView.swift
//  Riot
//
//  Created by Vũ Hai on 6/27/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

class CKRecentHeaderView: UIView {

    @IBOutlet weak var arrowImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    public class func instance() -> CKRecentHeaderView? {
        return UINib(nibName: "CKRecentHeaderView", bundle: nil).instantiate(withOwner: nil, options: nil).first as? CKRecentHeaderView
    }
    
    // MARK: - OVERRIDE
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = CKColor.Background.tableView
    }

    // MARK: - ACTION
    @IBAction func addChatAction(_ sender: UIButton) {
        
    }
    
    // MARK: - PUBLIC
    func blindData(title: String, numberChat: Int) {
        self.titleLabel.text = "\(title) (\(numberChat))"
    }
}
