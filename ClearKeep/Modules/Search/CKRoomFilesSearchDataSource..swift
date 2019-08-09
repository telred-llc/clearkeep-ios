//
//  CKRoomFilesSearchDataSource.swift
//  Riot
//
//  Created by Pham Hoa on 8/8/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

@objc public class CKRoomFilesSearchDataSource: CKSearchDataSource {
    var roomDataSource: RoomDataSource?

    override func getSearchType() -> CKSearchDataSource.SearchType {
        return .media
    }

    override func getRoomsForSearching() -> [MXRoom] {
        return [self.roomDataSource?.room].compactMap{ $0 }
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
                    // default: shouldShowRoomDisplayName is false
                    cellData.shouldShowRoomDisplayName = false

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

    /**
     Initialize a new `CKRoomFilesSearchDataSource` instance.

     @param roomDataSource a datasource to be able to rendering.
     @return the newly created instance.
     */
    @objc class func initWithRoomDataSource(_ roomDataSource: RoomDataSource?) -> CKRoomFilesSearchDataSource? {
        let instance = CKRoomFilesSearchDataSource.init(matrixSession: roomDataSource?.mxSession)
        instance?.roomDataSource = roomDataSource
        return instance
    }

}
