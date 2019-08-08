//
//  CKRoomCacheManager.swift
//  Riot
//
//  Created by Pham Hoa on 8/6/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation
import Cache

struct CKStoredRoom: Codable {
    var id: String
    var messages: [CKStoredMessage]
}

struct CKStoredMessage: Codable {
    var eventId: String
    var roomId: String
    var senderId: String
    var eventType: __MXEventType = __MXEventType.init(0)
    var content: String
    var isEncrypted = false

    enum CodingKeys: String, CodingKey
    {
        case eventId
        case roomId
        case senderId
        case eventType
        case content
        case isEncrypted
    }

    init(eventId: String, roomId: String, senderId: String, eventType: __MXEventType, content: String,  isEncrypted: Bool) {
        self.eventId = eventId
        self.roomId = roomId
        self.senderId = senderId
        self.eventType = eventType
        self.content = content
        self.isEncrypted = isEncrypted
    }

    init(from decoder: Decoder) throws
    {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        eventId = try values.decode(String.self, forKey: .eventId)
        roomId = try values.decode(String.self, forKey: .roomId)
        senderId = try values.decode(String.self, forKey: .senderId)
        content = try values.decode(String.self, forKey: .content)
        isEncrypted = try values.decode(Bool.self, forKey: .isEncrypted)
        let type = try values.decode(UInt.self, forKey: .eventType)
        eventType = __MXEventType.init(type)
    }

    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(eventId, forKey: .eventId)
        try container.encode(roomId, forKey: .roomId)
        try container.encode(senderId, forKey: .senderId)
        try container.encode(eventType.rawValue, forKey: .eventType)
        try container.encode(content, forKey: .content)
        try container.encode(isEncrypted, forKey: .isEncrypted)
    }
}

// MARK: - CKRoomCacheManager

@objcMembers
public class CKRoomCacheManager: NSObject {

    static let shared = CKRoomCacheManager()

    private var storage: HybridStorage<CKStoredRoom>!
    private let maxFirstFetchingMessagesCount: UInt = 10000
    private var roomsInSyncing: [String] = []

    private override init() {
        super.init()
        let memory = MemoryStorage<CKStoredRoom>(config: MemoryConfig())
        let disk = try! DiskStorage<CKStoredRoom>(config: DiskConfig(name: "HybridDisk"), transformer: TransformerFactory.forCodable(ofType: CKStoredRoom.self))

        storage = HybridStorage(memoryStorage: memory, diskStorage: disk)
    }

    func doCacheMessage(_ message: CKStoredMessage, roomId: String) {
        var storedRoom = getStoredRoom(roomId: roomId) ?? CKStoredRoom.init(id: roomId, messages: [])
        if let index = storedRoom.messages.firstIndex(where: { $0.eventId == message.eventId }) {
            storedRoom.messages[index] = message
        } else {
            storedRoom.messages.append(message)
        }
        try? storage.setObject(storedRoom, forKey: roomId)
    }

    func doCacheRoom(_ room: CKStoredRoom) {
        try? storage.setObject(room, forKey: room.id)
    }

    func getStoredRoom(roomId: String) -> CKStoredRoom? {
        return try? storage.object(forKey: roomId)
    }

    func getStoredMessage(eventId: String, roomId: String) -> CKStoredMessage? {
        let storedRoom = getStoredRoom(roomId: roomId)
        if let message = storedRoom?.messages.first(where: { $0.eventId == eventId }) {
            return message
        } else {
            return nil
        }
    }

    func syncAllRooms(mxSession: MXSession?) {
        guard let mxSession = mxSession else {
            return
        }

        mxSession.rooms.forEach { (room) in
            self.syncRoom(room: room, mxSession: mxSession)
        }
    }

    func syncRoom(room: MXRoom, mxSession: MXSession?) {
        guard let mxSession = mxSession else {
            return
        }

        let storedRoom = self.getStoredRoom(roomId: room.roomId)

        // If the app hasn't first fetched from server, will sync from server
        if let storedRoom = storedRoom, !storedRoom.messages.isEmpty {
            var events: [MXEvent] = []
            let enumeratorForStoredMessages = room.enumeratorForStoredMessages
            while let event = enumeratorForStoredMessages?.nextEvent {
                events.append(event)
            }

            self.doCache(events: events, roomId: room.roomId)
        } else {
            // If the room is syncing then return here
            if !roomsInSyncing.contains(room.roomId) {
                return
            }

            roomsInSyncing.append(room.roomId)
            DispatchQueue.global(qos: .background).async {
                self.syncRoomFromServer(roomId: room.roomId, mxSession: mxSession, onComplete: {
                    if let index = self.roomsInSyncing.index(of: room.roomId) {
                        self.roomsInSyncing.remove(at: index)
                    }
                })
            }
        }
    }

    func clearAllCachedData() {
        try? storage.removeAll()
    }
}

// MARK: - Private methods

private extension CKRoomCacheManager {
    func syncRoomFromServer(roomId: String, mxSession: MXSession?, onComplete: @escaping (() -> Void)) {
        guard let mxSession = mxSession else {
            onComplete()
            return
        }

        mxSession.matrixRestClient.intialSync(ofRoom: roomId, limit: self.maxFirstFetchingMessagesCount, completion: { [weak self] (response) in
            onComplete()
            if response.isSuccess, let roomResponse = response.value {
                if let events = roomResponse.messages?.chunk {
                    self?.doCache(events: events, roomId: roomId)
                }
            }
        })
    }

    func doCache(events: [MXEvent], roomId: String) {
        var cachedRoom = CKRoomCacheManager.shared.getStoredRoom(roomId: roomId) ?? CKStoredRoom.init(id: roomId, messages: [])
        events.forEach({ (event) in
            var content = ""
            if let contentData = try?  JSONSerialization.data(withJSONObject: event.content, options: .prettyPrinted) {
                content = String(data: contentData, encoding: String.Encoding.ascii) ?? ""
            }

            let message = CKStoredMessage.init(eventId: event.eventId, roomId: event.roomId, senderId: event.sender, eventType: event.eventType, content: content, isEncrypted: event.isEncrypted)
            if let index = cachedRoom.messages.firstIndex(where: { $0.eventId == message.eventId }) {
                cachedRoom.messages[index] = message
            } else {
                cachedRoom.messages.append(message)
            }
        })

        CKRoomCacheManager.shared.doCacheRoom(cachedRoom)
    }
}
