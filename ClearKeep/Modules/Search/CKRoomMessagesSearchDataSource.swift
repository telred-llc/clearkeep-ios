//
//  CKRoomMessagesSearchDataSource.swift
//  Riot
//
//  Created by Pham Hoa on 8/7/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

public class CKRoomMessagesSearchDataSource: CKSearchDataSource {

    var roomDataSource: RoomDataSource?
    
    override func getSearchType() -> CKSearchDataSource.SearchType {
        return .message
    }

    override func getRoomsForSearching() -> [MXRoom] {
        return [self.roomDataSource?.room].compactMap{ $0 }
    }

    override func getRoomDataSource(roomId: String, onComplete: @escaping ((MXKRoomDataSource?) -> Void)) {
        onComplete(roomDataSource)
    }

    override public func destroy() {
        roomDataSource = nil
        super.destroy()
    }

    /**
     Initialize a new `CKRoomMessagesSearchDataSource` instance.

     @param roomDataSource a datasource to be able to rendering.
     @return the newly created instance.
     */
    @objc class func initWithRoomDataSource(_ roomDataSource: RoomDataSource?) -> CKRoomMessagesSearchDataSource? {
        let instance = CKRoomMessagesSearchDataSource.init(matrixSession: roomDataSource?.mxSession)
        instance?.roomDataSource = roomDataSource

        // The messages search is limited to the room data.
        instance?.roomEventFilter.rooms = [roomDataSource?.roomId].compactMap{ $0 }

        return instance
    }
}
