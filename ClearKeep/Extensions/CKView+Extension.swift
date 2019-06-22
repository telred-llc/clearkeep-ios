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
}
