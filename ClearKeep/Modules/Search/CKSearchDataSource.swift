//
//  CKSearchDataSource.swift
//  Riot
//
//  Created by Pham Hoa on 8/7/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

@objc public class CKSearchDataSource: MXKSearchDataSource {

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
     Type of content for searching.
     - message: plaintext
     - media: image, video, file, location
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
    func getRoomsForSearching() -> [MXRoom] {
        return self.mxSession?.rooms ?? []
    }

    /**
     Get room data source by id
     - parameters:
        - roomId: The id of room
     */
    func getRoomDataSource(roomId: String, onComplete: @escaping ((MXKRoomDataSource?) -> Void)) {
        let roomDataSourceManager = MXKRoomDataSourceManager.sharedManager(forMatrixSession: self.mxSession)

        // Check whether the user knows this room to create the room data source if it doesn't exist.
        roomDataSourceManager?.roomDataSource(forRoom: roomId, create: self.mxSession.room(withRoomId: roomId) != nil, onComplete: { (roomDataSource) in
            onComplete(roomDataSource)
        })
    }

    /**
     Convert searched results into cells
     - parameters:
        - roomEvents: array of MXEvent
        - onComplete: closure for completion
     */
    func convertSearchedResultsIntoCells(roomEvents: [MXEvent], onComplete: @escaping (() -> Void)) {
        let dispatchGroup = DispatchGroup()
        for roomEvent in roomEvents {
            guard let roomId = roomEvent.roomId else { return }

            dispatchGroup.enter()

            getRoomDataSource(roomId: roomId) { [weak self] (roomDataSource) in
                if let roomDataSource = roomDataSource {
                    // Prepare text font used to highlight the search pattern.
                    let patternFont = roomDataSource.eventFormatter.bingTextFont

                    if let cellData = RoomBubbleCellData.init(event: roomEvent, andRoomState: roomDataSource.roomState, andRoomDataSource: roomDataSource) {

                        cellData.highlightPattern(inTextMessage: self?.searchText, withForegroundColor: themeService.attrs.navBarTintColor, andFont: patternFont)

                        // Use profile information as data to display
                        if let sender = roomDataSource.roomState?.members.members.first(where: { $0.userId == roomEvent.sender }) {
                            cellData.senderDisplayName = sender.displayname
                            cellData.senderAvatarUrl = sender.avatarUrl
                        } else {
                            cellData.senderDisplayName = roomDataSource.room.summary.displayname
                            cellData.senderAvatarUrl = nil
                        }

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

    /**
     Extract event content form an event.
     - parameters:
     - event: an item of MXEvent
     */
    func getEventContent(event: MXEvent) -> [String: Any] {
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

        return eventContent
    }

    /**
     Extract decrypted message body content form an event.
     - parameters:
     - event: an item of MXEvent
     */
    func getBodyMessage(eventContent: [String: Any], isMediaAttachment: Bool, isSearching: Bool = false) -> String? {
        if let msgtype = eventContent["msgtype"] as? String {
            switch getSearchType() {
            case .message:
                if msgtype == kMXMessageTypeText {
                    if isSearching {
                        if let newContent = eventContent["m.new_content"] as? [String: Any], let newBody = newContent["body"] as? String {
                            return newBody
                        } else {
                            return eventContent["body"] as? String
                        }
                    } else {
                        return eventContent["body"] as? String
                    }
                }
            case .media:
                if isMediaAttachment {
                    if msgtype == kMXMessageTypeFile ||
                        msgtype == kMXMessageTypeAudio ||
                        msgtype == kMXMessageTypeVideo ||
                        msgtype == kMXMessageTypeImage {
                        let messageBody = eventContent["body"] as? String
                        return messageBody
                    }
                }
            }
        }

        return nil
    }

    override public func doSearch() {
        let searchRooms = getRoomsForSearching()
        var filteredEvents: [MXEvent] = []
        for room in searchRooms {
            guard let roomId = room.roomId else { return }
            if let cachedRoom = CKRoomCacheManager.shared.getStoredRoom(roomId: roomId) {
                let messages = cachedRoom.messages.compactMap{ $0.copy() as? CKStoredMessage }
                messages.forEach { (message) in
                    if let event = self.mxSession.store.event(withEventId: message.eventId, inRoom: message.roomId),
                        let coppiedEvent = MXEvent.init(fromJSON: event.jsonDictionary()) {

                        // Check eventType
                        if coppiedEvent.eventType == __MXEventTypeRoomEncrypted ||
                            coppiedEvent.eventType == __MXEventTypeRoomMessage {

                            var decryptedEventContent = self.getEventContent(event: event)

                            if let relates = event.content["m.relates_to"] {
                                decryptedEventContent["m.relates_to"] = relates
                            }

                            // Set event as is decrypted event
                            coppiedEvent.wireEventType = __MXEventTypeRoomMessage
                            coppiedEvent.wireContent = decryptedEventContent
                            
                            // extract body message
                            let bodyMessage = getBodyMessage(eventContent: decryptedEventContent, isMediaAttachment: coppiedEvent.isMediaAttachment())
                            
                            // match body message with search text
                            if bodyMessage?.lowercased().contains(self.searchText.lowercased()) == true {
                                filteredEvents.append(coppiedEvent)
                            }
                        }
                    }
                }
            }
        }

        filteredEvents = filteredEvents.filter({ (event) -> Bool in
            if let relateInfo = event.relatesTo, relateInfo.relationType == MXEventRelationTypeReplace {
                return false
            } else {
                return true
            }
        })

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
}

extension CKSearchDataSource {
    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)

        if cell.isKind(of: RoomIncomingAttachmentBubbleCell.self), let cellObject = cell as? RoomIncomingAttachmentBubbleCell {
            cellObject.isSearchCell = true
        } else if cell.isKind(of: RoomIncomingTextMsgBubbleCell.self), let cellObject = cell as? RoomIncomingTextMsgBubbleCell {
            cellObject.isSearchCell = true
        }

        if cell.isKind(of: MXKRoomBubbleTableViewCell.self), let bubbleCell = cell as? MXKRoomBubbleTableViewCell {
            bubbleCell.updateEventFormatter()
            bubbleCell.addDateLabel(false)
        } else if cell.isKind(of: FilesSearchTableViewCell.self), let fileSearchCell = cell as? FilesSearchTableViewCell {
            if (self.cellDataArray?.count ?? 0) > indexPath.row,
                let cellData = self.cellDataArray?[indexPath.row] as? CKFilesSearchCellData,
                let attachment = cellData.attachment {

                fileSearchCell.title.text = attachment.originalFileName

                if cellData.isAttachmentWithThumbnail {
                    fileSearchCell.attachmentImageView.backgroundColor = kRiotPrimaryBgColor
                    fileSearchCell.attachmentImageView.setAttachmentThumb(attachment)
                } else {
                    fileSearchCell.attachmentImageView.image = nil
                    fileSearchCell.attachmentImageView.backgroundColor = UIColor.clear
                }

                fileSearchCell.message.text = cellData.message
                fileSearchCell.iconImage.image = cellData.attachmentIcon
                if let fileTitle = cellData.extraInfo {
                    fileSearchCell.message.text = fileTitle
                }

                // Disable any interactions defined in the cell
                // because we want [tableView didSelectRowAtIndexPath:] to be called
                fileSearchCell.contentView.isUserInteractionEnabled = false
            } else {
                fileSearchCell.title.text = nil
                fileSearchCell.date.text = nil
                fileSearchCell.message.text = ""
                fileSearchCell.attachmentImageView.image = nil;
                fileSearchCell.iconImage.image = nil;
            }
        }
        
        return cell
    }
}
