//
//  CKHomePagingCell.swift
//  Riot
//
//  Created by Pham Hoa on 2/15/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit
import Parchment

class CKHomePagingWithBubbleCell: PagingCell {

    @IBOutlet weak var contentStackView: UIStackView!
    @IBOutlet weak var pagingTitleLabel: UILabel!
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var bubbleTitleLabel: UILabel!
        
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setPagingItem(_ pagingItem: PagingItem, selected: Bool, options: PagingOptions) {
        if let ckPagingItem = pagingItem as? CKPagingIndexItem {
            pagingTitleLabel.text = ckPagingItem.title
            
            // style
            bubbleTitleLabel.textColor = UIColor.white
            bubbleTitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
            
            if selected {
                pagingTitleLabel.font = options.selectedFont
                pagingTitleLabel.textColor = options.selectedTextColor
                backgroundColor = options.selectedBackgroundColor
            } else {
                pagingTitleLabel.font = options.font
                pagingTitleLabel.textColor = options.textColor
                backgroundColor = options.backgroundColor
            }
            
            // layout
            if let bubbleTitle = ckPagingItem.bubbleTitle {
                bubbleTitleLabel.text = bubbleTitle
                
                bubbleView.isHidden = false
                bubbleView.clipsToBounds = true
                contentStackView.spacing = 8
                self.layoutIfNeeded()
                bubbleView.layer.cornerRadius = bubbleView.frame.size.width/2
            } else {
                bubbleTitleLabel.text = nil
                bubbleView.isHidden = true
                contentStackView.spacing = 0
            }
            pagingTitleLabel.font = CKAppTheme.mainMediumAppFont(size: 15)
        } else {
            pagingTitleLabel.text = nil
            bubbleTitleLabel.text = nil
            bubbleView.isHidden = true
        }
    }
}
