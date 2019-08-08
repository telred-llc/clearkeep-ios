//
//  CKSearchDataSource.swift
//  Riot
//
//  Created by Pham Hoa on 8/7/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

public class CKSearchDataSource: MXKSearchDataSource {

    /**
     List of results retrieved from the server.
     The` MXKSearchDataSource` class stores MXKSearchCellDataStoring objects in it.
     cellDataArray is kind of [MXKCellData]
     */
    var cellDataArray: NSMutableArray? {
        get {
            return super.value(forKey: "cellDataArray") as? NSMutableArray
        }
        set {
            super.setValue(newValue, forKey: "cellDataArray")
        }
    }

    /**
     Type of content for searching
    */
    enum SearchType {
        case message
        case media
    }

    // Override this method in your subclass
    func getSearchType() -> SearchType {
        return .message
    }

    // Override this method in your subclass
    func getSearchTyp() -> SearchType {
        return .message
    }

    func getRoomsForSearching() -> [MXRoom] {
        return self.mxSession?.rooms ?? []
    }

    func getRoomDataSource(roomId: String, onComplete: @escaping ((MXKRoomDataSource?) -> Void)) {
        let roomDataSourceManager = MXKRoomDataSourceManager.sharedManager(forMatrixSession: self.mxSession)

        // Check whether the user knows this room to create the room data source if it doesn't exist.
        roomDataSourceManager?.roomDataSource(forRoom: roomId, create: self.mxSession.room(withRoomId: roomId) != nil, onComplete: { (roomDataSource) in
            onComplete(roomDataSource)
        })
    }

    public override func finalizeInitialization() {
        super.finalizeInitialization()
    }
    override public func doSearch() {
        let searchRooms = getRoomsForSearching()
        var filteredEvents: [MXEvent] = []

        for room in searchRooms {
            guard let roomId = room.roomId else { return }

            if let cachedRoom = CKRoomCacheManager.shared.getStoredRoom(roomId: roomId) {
                cachedRoom.messages.forEach { (message) in
                    if let event = self.mxSession.store.event(withEventId: message.eventId, inRoom: message.roomId) {

                        // Check eventType
                        if event.eventType == __MXEventTypeRoomEncrypted ||
                            event.eventType == __MXEventTypeRoomMessage {

                            // extract body message
                            let bodyMessage = getBodyMessage(event: event)

                            // match body message with search text
                            if bodyMessage?.lowercased().contains(self.searchText.lowercased()) == true {
                                filteredEvents.append(event)
                            }
                        }
                    }
                }
            }
        }

        convertSearchedResultsIntoCells(roomEvents: filteredEvents, onComplete: { [weak self] in
            self?.setState(MXKDataSourceStateReady)
            // Provide changes information to the delegate
            var insertedIndexes: NSIndexSet?
            if filteredEvents.count > 0 {
                insertedIndexes = NSIndexSet.init(indexesIn: NSMakeRange(0, filteredEvents.count))
            }

            self?.delegate.dataSource(self, didCellChange: insertedIndexes)
        })
    }

    private func convertSearchedResultsIntoCells(roomEvents: [MXEvent], onComplete: @escaping (() -> Void)) {
        let dispatchGroup = DispatchGroup()

        for roomEvent in roomEvents {
            guard let roomId = roomEvent.roomId else { return }

            dispatchGroup.enter()

            getRoomDataSource(roomId: roomId) { [weak self] (roomDataSource) in
                if let roomDataSource = roomDataSource {
                    // Prepare text font used to highlight the search pattern.
                    let patternFont = roomDataSource.eventFormatter.bingTextFont

                    // Let the `RoomViewController` ecosystem do the job
                    // The search result contains only room message events, no state events.
                    // Thus, passing the current room state is not a huge problem. Only
                    // the user display name and his avatar may be wrong.
                    if let cellData = RoomBubbleCellData.init(event: roomEvent, andRoomState: roomDataSource.roomState, andRoomDataSource: roomDataSource) {
                        cellData.highlightPattern(inTextMessage: self?.searchText, withForegroundColor: kRiotColorGreen, andFont: patternFont)

                        // Use profile information as data to display
                        if let sender = roomDataSource.roomState?.members.members.first(where: { $0.userId == roomEvent.sender }) {
                            cellData.senderDisplayName = sender.displayname
                            cellData.senderAvatarUrl = sender.avatarUrl
                        } else {
                            cellData.senderDisplayName = roomDataSource.room.summary.displayname
                            cellData.senderAvatarUrl = nil
                        }

                        // Show decrypted message
                        let decryptedMessage = self?.getBodyMessage(event: roomEvent)
                        cellData.textMessage = decryptedMessage
                        cellData.attributedTextMessage = self?.eventFormatter.renderString(decryptedMessage ?? "", for: roomEvent)

                        self?.cellDataArray?.add(cellData)
                    }
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

    private func getBodyMessage(event: MXEvent) -> String? {
        var eventContent: [String: Any] = [:]
        if event.isEncrypted {
            if let clearEvent = try? self.mxSession.crypto?.decryptEvent(event, inTimeline: nil).clearEvent,
                let content = clearEvent?["content"] as? [String: Any] {
                eventContent = content
            } else if let content = event.content {
                eventContent = content
            }
        } else {
            if let content = event.content {
                eventContent = content
            }
        }

        if let msgtype = eventContent["msgtype"] as? String {
            switch getSearchType() {
            case .message:
                if msgtype == kMXMessageTypeText {
                    let messageBody = eventContent["body"] as? String
                    return messageBody
                }
            case .media:
                if msgtype == kMXMessageTypeFile,
                    msgtype == kMXMessageTypeAudio,
                    msgtype == kMXMessageTypeVideo,
                    msgtype == kMXMessageTypeImage {
                    let messageBody = eventContent["body"] as? String
                    return messageBody
                }
            }
        }

        return nil
    }
}

extension CKSearchDataSource {
    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)

        if cell.isKind(of: MXKRoomBubbleTableViewCell.self), let bubbleCell = cell as? MXKRoomBubbleTableViewCell {
            bubbleCell.addDateLabel(false)
        }
        return cell
    }
}
