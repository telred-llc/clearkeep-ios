//
//  CKRoomSettingsParticipantSearchCell.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/22/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKRoomSettingsParticipantSearchCell: CKRoomSettingsBaseCell {

    // MARK: - OUTLET
    @IBOutlet weak var searchBar: UISearchBar!
    
    // MARK: - PROPERTY
    internal var beginSearchingHandler: ((String) -> Void)?

    // MARK: - OVERRIDE
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.searchBar.placeholder = CKLocalization.string(byKey: "search_default_placeholder")
        self.searchBar.delegate = self
        
        self.searchBar.vc_searchTextField?.theme.backgroundColor = themeService.attrStream{ $0.searchBarBgColor }
        self.searchBar.vc_searchTextField?.theme.textColor = themeService.attrStream{ $0.secondTextColor }
        self.searchBar.setMagnifyingGlassColorTo(color: themeService.attrs.secondTextColor)
        self.searchBar.setClearButtonColorTo(color: themeService.attrs.secondTextColor)
        self.searchBar.theme.backgroundColor = themeService.attrStream{ $0.primaryBgColor }
        self.searchBar.theme.barTintColor = themeService.attrStream{ $0.primaryBgColor }
        self.searchBar.vc_searchTextField?.theme.tintColor = themeService.attrStream{ $0.placeholderTextFieldColor }
    }
}

extension CKRoomSettingsParticipantSearchCell: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        beginSearchingHandler?(searchText)
    }
}

