//
//  CKColor.swift
//  Riot
//
//  Created by Pham Hoa on 1/3/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

class CKColor {
    struct Text {
        static let lightText: UIColor = UIColor.lightText
        static let lightGray: UIColor = UIColor.lightGray
        static let lightBlueText: UIColor = #colorLiteral(red: 0.1411764706, green: 0.5215686275, blue: 0.6705882353, alpha: 1)
    }
    
    struct Background {
        static let navigationBar: UIColor = UIColor.init(red: 247/255, green: 247/255, blue: 247/255, alpha: 1)
        static let tableView: UIColor = #colorLiteral(red: 0.9763854146, green: 0.9765253663, blue: 0.9763547778, alpha: 1)
    }
    
    struct Misc {
        static let primaryGreenColor: UIColor = UIColor.init(red: 99/255, green: 205/255, blue: 156/255, alpha: 1)
    }
}
