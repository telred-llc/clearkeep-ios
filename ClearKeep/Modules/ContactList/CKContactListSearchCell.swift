//
//  CKContactListSearchCell.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/28/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKContactListSearchCell: CKContactListBaseCell {
    
    // MARK: - OUTLET
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    // MARK: - PROPERTY

    internal var beginSearchingHandler: ((String) -> Void)?
    
    // MARK: - OVERRIDE
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.searchBar.delegate = self
        self.searchBar.placeholder = "Filter contacts"
    }
}

extension CKContactListSearchCell: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        beginSearchingHandler?(searchText)
    }
}


