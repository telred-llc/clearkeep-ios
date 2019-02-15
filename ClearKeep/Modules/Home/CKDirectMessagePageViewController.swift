//
//  CKDirectMessagePageViewController.swift
//  Riot
//
//  Created by Pham Hoa on 1/3/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

class CKDirectMessagePageViewController: CKRecentListViewController {
    
    var missedItemCount: Int = 0

    override func reloadData(rooms: [MXKRecentCellData]) {
        super.reloadData(rooms: rooms)
        
        // keep missedItemCount
        self.missedItemCount = rooms.filter({ $0.hasUnread || $0.notificationCount > 0 }).count
    }
}
