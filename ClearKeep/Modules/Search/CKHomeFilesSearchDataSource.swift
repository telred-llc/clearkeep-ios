//
//  CKHomeFilesSearchDataSource.swift
//  Riot
//
//  Created by Pham Hoa on 8/8/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

@objc public class CKHomeFilesSearchDataSource: CKSearchDataSource {
    override func getSearchType() -> CKSearchDataSource.SearchType {
        return .media
    }

    override func convertSearchedResultsIntoCells(roomEvents: [MXEvent], onComplete: @escaping (() -> Void)) {
        let dispatchGroup = DispatchGroup()

        for roomEvent in roomEvents {
            guard let roomId = roomEvent.roomId else { return }

            dispatchGroup.enter()

            getRoomDataSource(roomId: roomId) { [weak self] (roomDataSource) in
                if let _ = roomDataSource {
                    let cellData = CKFilesSearchCellData.init(event: roomEvent, searchDataSource: self)                    
                    // Custom cell data here

                    self?.cellDataArray?.add(cellData)
                }

                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            // In case of successive messages from the same room,
            // we use the pagination flag to display the room name only on the first message.
            var currentRoomId: String?
            let cellDatas = self.cellDataArray ?? []
            for cellData in cellDatas {
                let bubbleCellData = cellData as? RoomBubbleCellData
                if let currentRoomId = currentRoomId, currentRoomId == bubbleCellData?.roomId {
                    bubbleCellData?.isPaginationFirstBubble = false
                } else {
                    bubbleCellData?.isPaginationFirstBubble = true
                    currentRoomId = bubbleCellData?.roomId
                }
            }

            onComplete()
        }
    }
}
