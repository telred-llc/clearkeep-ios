//
//  CKSearchBarContainerView.swift
//  Riot
//
//  Created by Pham Hoa on 2/1/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

@objc class CKSearchBarContainerView: UIView {
    
    let searchBar: UISearchBar
    
    init(customSearchBar: UISearchBar) {
        searchBar = customSearchBar

        if let textfield = searchBar.vc_searchTextField {
            textfield.theme.backgroundColor = themeService.attrStream{$0.searchBarBgColor}
        }

        super.init(frame: CGRect.zero)
        addSubview(searchBar)
    }
    
    override convenience init(frame: CGRect) {
        self.init(customSearchBar: UISearchBar())
        self.frame = frame
    }
    
    @objc
    convenience init(searchBar: UISearchBar) {
        self.init(customSearchBar: searchBar)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        searchBar.frame = bounds
    }
}
