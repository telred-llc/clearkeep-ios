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
        self.searchBar.placeholder = "Filter participants"
        self.searchBar.delegate = self
        self.selectionStyle = .none
        self.searchBar.vc_searchTextField?.backgroundColor = themeService.attrs.searchBarBgColor
        self.searchBar.vc_searchTextField?.textColor = themeService.attrs.secondTextColor
        self.searchBar.setMagnifyingGlassColorTo(color: themeService.attrs.secondTextColor)
        self.searchBar.setClearButtonColorTo(color: themeService.attrs.secondTextColor)
    }
}

extension CKRoomSettingsParticipantSearchCell: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        beginSearchingHandler?(searchText)
    }
}

