//
//  CKHomeMessagesSearchDataSource.swift
//  Riot
//
//  Created by Pham Hoa on 8/6/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

class CKHomeMessagesSearchDataSource: CKSearchDataSource {
    override func getSearchType() -> CKSearchDataSource.SearchType {
        return .message
    }
}
