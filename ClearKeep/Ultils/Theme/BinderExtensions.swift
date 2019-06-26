//
//  BinderExtensions.swift
//  Riot
//
//  Created by Pham Hoa on 6/22/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit
import Parchment
import RxCocoa
import RxTheme

extension Reactive where Base: UITextField {
    var placeHolderColor: Binder<UIColor?> {
        return Binder(self.base) { view, color in
            view.attributedPlaceholder = NSAttributedString.init(string: view.placeholder ?? "", attributes: [NSAttributedString.Key.foregroundColor : color ?? UIColor.gray])
        }
    }
}

extension ThemeProxy where Base: UITextField {
    var placeHolderColor: Observable<UIColor?> {
        get { return .empty() }
        set {
            let disposable = newValue
                .takeUntil(base.rx.deallocating)
                .observeOn(MainScheduler.instance)
                .bind(to: base.rx.placeHolderColor)
            hold(disposable, for: "placeHolderColor")
        }
    }
}
