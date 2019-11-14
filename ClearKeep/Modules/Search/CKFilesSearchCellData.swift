
//
//  CKFilesSearchCellData.swift
//  Riot
//
//  Created by Pham Hoa on 8/8/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

@objc public class CKFilesSearchCellData: MXKCellData, MXKSearchCellDataStoring {

    // MARK: MXKSearchCellDataStoring
    public var message: String!
    public var roomId: String?
    public var title: String?
    public var extraInfo: String?
    public var age: String?
    public var date: String?
    public var searchResult: MXSearchResult?
    public var roomDisplayName: String?
    public var senderDisplayName: String?
    public var attachment: MXKAttachment?

    public var shouldShowRoomDisplayName: Bool = false {
        didSet {
            self.setShouldShowRoomDisplayName(self.shouldShowRoomDisplayName)
        }
    }

    public var isAttachmentWithThumbnail: Bool {
        get {
            if let attachment = attachment {
                if attachment.type == MXKAttachmentTypeImage || attachment.type == MXKAttachmentTypeVideo || attachment.type == MXKAttachmentTypeSticker {
                    return true
                }
            }

            return false
        }
    }
    
    public var attachmentIcon: UIImage? {
        get {
            var image: UIImage? = nil

            if let attachmentType = attachment?.type {
                switch attachmentType {
                case MXKAttachmentTypeImage:
                    image = UIImage(named: "file_photo_icon")?.withRenderingMode(.alwaysTemplate)
                case MXKAttachmentTypeAudio:
                    image = UIImage(named: "file_music_icon")?.withRenderingMode(.alwaysTemplate)
                case MXKAttachmentTypeVideo:
                    image = UIImage(named: "file_video_icon")?.withRenderingMode(.alwaysTemplate)
                case MXKAttachmentTypeFile:
                    image = UIImage(named: "file_doc_icon")?.withRenderingMode(.alwaysTemplate)
                default:
                    break
                }
            }

            return image
        }
    }

    /**
     The data source owner of this instance.
     */
    var searchDataSource: MXKSearchDataSource?

    /**
     Search Event
    */
    @objc var event: MXEvent!


    public class func cellData(with searchResult: MXSearchResult!, andSearchDataSource searchDataSource: MXKSearchDataSource!, onComplete: ((MXKSearchCellDataStoring?) -> Void)!) {
        let cellData = self.init(event: searchResult.result, searchDataSource: searchDataSource)

        // Retrieve the sender display name from the current room state
        if let room = searchDataSource.mxSession.room(withRoomId: cellData.roomId) {
            room.state({ roomState in
                cellData.senderDisplayName = roomState?.members.memberName(searchResult.result.sender)
                cellData.message = cellData.senderDisplayName

                onComplete(cellData)
            })
        } else {
            cellData.senderDisplayName = searchResult.result.sender
            cellData.message = cellData.senderDisplayName

            onComplete(cellData)
        }
    }

    public class func cellData(event: MXEvent!, andSearchDataSource searchDataSource: MXKSearchDataSource!, onComplete: ((MXKSearchCellDataStoring?) -> Void)!) {
        let cellData = self.init(event: event, searchDataSource: searchDataSource)

        // Retrieve the sender display name from the current room state
        if let room = searchDataSource.mxSession.room(withRoomId: cellData.roomId) {
            room.state({ roomState in
                cellData.senderDisplayName = roomState?.members.memberName(event.sender)
                cellData.message = cellData.senderDisplayName

                onComplete(cellData)
            })
        } else {
            cellData.senderDisplayName = event.sender
            cellData.message = cellData.senderDisplayName

            onComplete(cellData)
        }
    }

    public required convenience init(event: MXEvent, searchDataSource: MXKSearchDataSource?) {
        self.init()
        self.searchDataSource = searchDataSource
        self.event = event
        
        // Title is here the file name stored in event body
        if let searchDataSource = searchDataSource as? CKSearchDataSource {
            let decryptedEventContent = searchDataSource.getEventContent(event: event)
            title = searchDataSource.getBodyMessage(eventContent: decryptedEventContent, isMediaAttachment: event.isMediaAttachment())
        } else {
            title = nil
        }

        roomId = event.roomId

        // Check attachment if any
        if let searchDataSource = searchDataSource {
            // Note: event.eventType may be equal here to MXEventTypeRoomMessage or MXEventTypeSticker
            attachment = MXKAttachment(event: event, andMediaManager: searchDataSource.mxSession.mediaManager)
        }

        // Append the file size if any
        if let contentInfo = attachment?.contentInfo as? [String: Any] {
            if let size = contentInfo["size"] as? Int {
                title = "\(String(describing: title)) (\(String(describing: MXTools.fileSize(toString: size, round: true))))"
                extraInfo = MXTools.fileSize(toString: size, round: true)
            }
        }

        date = searchDataSource?.eventFormatter.dateString(from: event, withTime: false)
    }
}

extension CKFilesSearchCellData {
    func setShouldShowRoomDisplayName(_ shouldShowRoomDisplayName: Bool) {
        if shouldShowRoomDisplayName {
            if let roomId = roomId, let room = self.searchDataSource?.mxSession?.room(withRoomId: roomId) {
                self.roomDisplayName = room.summary?.displayname
                if (self.roomDisplayName ?? "").isEmpty {
                    roomDisplayName = Bundle.mxk_localizedString(forKey: "room_displayname_empty_room")
                }
            } else {
                self.roomDisplayName = roomId
            }

            if let roomDisplayName = roomDisplayName, let senderDisplayName = senderDisplayName {
                message = "\(roomDisplayName) - \(senderDisplayName)"
            } else {
                message = ""
            }
        } else {
            message = senderDisplayName
        }
    }
}
