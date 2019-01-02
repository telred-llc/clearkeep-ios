//
//  CkHomeViewController.swift
//  Riot
//
//  Created by Sinbad Flyce on 12/28/18.
//  Copyright © 2018 matrix.org. All rights reserved.
//

import Foundation
import MatrixKit

final class CkHomeViewController: MXKViewController {
    
    @objc public func displayList(_ recentsDataSource: MXKRecentsDataSource) {
        
    }
    
    @objc public func dataSource(_ dataSource: MXKDataSource?, didCellChange changes: Any?) {
    }
    
    @objc public func cellViewClass(forCellData cellData: MXKCellData?) -> AnyClass {
        if let cellDataStoring = cellData as? MXKRecentCellDataStoring {
            if let roomSummary = cellDataStoring.roomSummary {
                if let room = roomSummary.room {
                    if let summary = room.summary {
                        if summary.membership != MXMembership.invite {
                            return MXKRecentTableViewCell.self
                        }
                    }
                }
            }
        }
        
        return MXKRecentTableViewCell.self
    }
}
