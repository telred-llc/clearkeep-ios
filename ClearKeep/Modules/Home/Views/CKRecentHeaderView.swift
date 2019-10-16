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
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var imageDescription: UIImageView!
    
    internal var addOnPressHandler: (() -> Void)?
    internal var onPressHandler: (() -> Void)?
    
    public class func instance() -> CKRecentHeaderView? {
        return UINib(nibName: "CKRecentHeaderView", bundle: nil).instantiate(withOwner: nil, options: nil).first as? CKRecentHeaderView
    }
    
    // MARK: - OVERRIDE
    override func awakeFromNib() {
        super.awakeFromNib()
        self.arrowImageView.image = self.arrowImageView.image?.withRenderingMode(.alwaysTemplate)
        self.arrowImageView.theme.tintColor = themeService.attrStream { $0.primaryTextColor }
        
        // add tap gesture to cell
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(onHeaderViewTap))
        tap.cancelsTouchesInView = true
        self.addGestureRecognizer(tap)
        
    }

    // MARK: - ACTION
    @IBAction func addChatAction(_ sender: UIButton) {
        self.addOnPressHandler?()
    }
    
    @objc func onHeaderViewTap(_ gesture: UIGestureRecognizer) {
        self.onPressHandler?()
    }
    
    // MARK: - PUBLIC
    func setTitle(title: String, numberChat: Int) {
        self.titleLabel.text = "\(title) (\(numberChat))"
    }
    
    func setImageDescription(nameImage : String){
        self.imageDescription.image = UIImage(named: nameImage)
    }
    
    func tapHeader(isExpanded: Bool) {
        if isExpanded {
            UIView.animate(withDuration: 0.5, animations: {
                self.arrowImageView.transform = CGAffineTransform.identity
            })
        } else {
            UIView.animate(withDuration: 0.5) {
                self.arrowImageView.transform = CGAffineTransform(rotationAngle: .pi * 3 / 2)
            }
        }
    }
}
