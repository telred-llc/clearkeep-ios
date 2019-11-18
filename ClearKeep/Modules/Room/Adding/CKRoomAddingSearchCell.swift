//
//  CKRoomAddingSearchCell.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/22/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKRoomAddingSearchCell: CKRoomBaseCell {

    // MARK: - OUTLET
    @IBOutlet weak var searchBar: UISearchBar!
    
    // MARK: - PROPERTY
    internal var beginSearchingHandler: ((String) -> Void)?

    // MARK: - OVERRIDE
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.searchBar.placeholder = CKLocalization.string(byKey: "search_default_placeholder")
        self.searchBar.delegate = self
 
        self.searchBar.vc_searchTextField?.backgroundColor = themeService.attrs.searchBarBgColor
        self.searchBar.vc_searchTextField?.textColor = themeService.attrs.secondTextColor
        self.searchBar.setMagnifyingGlassColorTo(color: themeService.attrs.secondTextColor)
        self.searchBar.setClearButtonColorTo(color: themeService.attrs.secondTextColor)

    }    
}

extension CKRoomAddingSearchCell: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        beginSearchingHandler?(searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

