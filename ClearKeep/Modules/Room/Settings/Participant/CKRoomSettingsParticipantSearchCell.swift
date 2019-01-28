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
        self.searchBar.placeholder = "Find participant"
        self.searchBar.delegate = self
    }
}

extension CKRoomSettingsParticipantSearchCell: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        beginSearchingHandler?(searchText)
    }
}

