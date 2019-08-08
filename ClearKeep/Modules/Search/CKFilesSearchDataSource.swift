//
//  CKFilesSearchDataSource.swift
//  Riot
//
//  Created by Pham Hoa on 8/8/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

public class CKFilesSearchDataSource: CKSearchDataSource {
    override public func finalizeInitialization() {
        super.finalizeInitialization()
    }

    override func getSearchType() -> CKSearchDataSource.SearchType {
        return .media
    }
}
