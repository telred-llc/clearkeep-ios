//
//  CKView+Extension.swift
//  Riot
//
//  Created by Pham Hoa on 6/22/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

extension UIView {
    
    func getViewElement<T>(type: T.Type) -> T? {

        let svs = subviews.flatMap { $0.subviews }
        guard let element = (svs.filter { $0 is T }).first as? T else { return nil }
        return element
    }
    
    /// Add a subview matching parent view using autolayout
    func vc_addSubViewMatchingParent(_ subView: UIView) {
        self.addSubview(subView)
        subView.translatesAutoresizingMaskIntoConstraints = false
        let views = ["view": subView]
        ["H:|[view]|", "V:|[view]|"].forEach { vfl in
            let constraints = NSLayoutConstraint.constraints(withVisualFormat: vfl,
                                                             options: [],
                                                             metrics: nil,
                                                             views: views)
            constraints.forEach { $0.isActive = true }
        }
    }
}

extension UILabel {
    func circle(){
        self.layer.cornerRadius = self.frame.width/2
        self.layer.masksToBounds = true
    }
}
