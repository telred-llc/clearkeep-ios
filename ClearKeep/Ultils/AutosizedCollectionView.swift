//
//  AutosizedCollectionView.swift
//  Riot
//
//  Created by klinh on 10/25/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

class AutosizedCollectionView: UICollectionView {

    override var contentSize: CGSize {
        didSet {
            self.invalidateIntrinsicContentSize()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return self.contentSize
    }
}
