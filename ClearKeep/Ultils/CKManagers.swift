//
//  CKManagers.swift
//  Riot
//
//  Created by Pham Hoa on 8/6/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation
import Cache
import Alamofire

class CKStoredRoom: Codable, NSCopying {
    var id: String
    var messages: [CKStoredMessage]

    init(id: String, messages: [CKStoredMessage]) {
        self.id = id
        self.messages = messages
    }

    func copy(with zone: NSZone? = nil) -> Any {
        let copy = CKStoredRoom.init(id: id, messages: messages)
        return copy
    }
}

class CKStoredMessage: Codable, NSCopying {
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

    func copy(with zone: NSZone? = nil) -> Any {
        let copy = CKStoredMessage.init(eventId: eventId, roomId: roomId, senderId: senderId, eventType: eventType, content: content, isEncrypted: isEncrypted)
        return copy
    }

    required init(from decoder: Decoder) throws
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

    /**
     Keep the roomIds which is requesting.
    */
    private var roomsInSyncing: [String] = []

    private override init() {
        super.init()
        let memory = MemoryStorage<CKStoredRoom>(config: MemoryConfig())
        let disk = try! DiskStorage<CKStoredRoom>(config: DiskConfig(name: "HybridDisk"), transformer: TransformerFactory.forCodable(ofType: CKStoredRoom.self))

        storage = HybridStorage(memoryStorage: memory, diskStorage: disk)
    }

    /**
     Do cache a message in room.
     */
    func doCacheMessage(_ message: CKStoredMessage, roomId: String) {
        let storedRoom = getStoredRoom(roomId: roomId) ?? CKStoredRoom.init(id: roomId, messages: [])

        if !storedRoom.messages.contains(where: { $0.eventId == message.eventId }) {
            storedRoom.messages.append(message)
        }

        try? storage.setObject(storedRoom, forKey: roomId)
    }

    /**
     Do cache a room.
     */
    func doCacheRoom(_ room: CKStoredRoom) {
        try? storage.setObject(room, forKey: room.id)
    }

    /**
     Get a room by roomId.
     */
    func getStoredRoom(roomId: String) -> CKStoredRoom? {
        return try? storage.object(forKey: roomId)
    }

    /**
     Get a message by eventId in room.
     */
    func getStoredMessage(eventId: String, roomId: String) -> CKStoredMessage? {
        let storedRoom = getStoredRoom(roomId: roomId)
        if let message = storedRoom?.messages.first(where: { $0.eventId == eventId }) {
            return message
        } else {
            return nil
        }
    }

    /**
     Sync all rooms.
     */
    func syncAllRooms(mxSession: MXSession?) {
        guard let mxSession = mxSession else {
            return
        }

        mxSession.rooms.forEach { (room) in
            self.syncRoom(room: room, mxSession: mxSession)
        }
    }

    /**
     Sync a room. If the app hasn't first fetched from server, if YES - will sync from server and if NO - will sync from local room.
     */
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

            // Cache in background to improve performance
            DispatchQueue.global(qos: .background).async {
                self.doCache(events: events, roomId: room.roomId)
            }
        } else {
            // If the room is syncing then return here
            if roomsInSyncing.contains(room.roomId) {
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

    /**
     Clear all cached data.
     */
    func clearAllCachedData() {
        try? storage.removeAll()
    }
}

// MARK: - Private methods

private extension CKRoomCacheManager {

    /**
     Sync room from server.
     */
    func syncRoomFromServer(roomId: String, mxSession: MXSession?, onComplete: @escaping (() -> Void)) {
        guard let mxSession = mxSession else {
            onComplete()
            return
        }

        mxSession.matrixRestClient.intialSync(ofRoom: roomId, limit: self.maxFirstFetchingMessagesCount, completion: { [weak self] (response) in
            onComplete()
            if response.isSuccess, let roomResponse = response.value {
                if let events = roomResponse.messages?.chunk {
                    // Cache in background to improve performance
                    DispatchQueue.global(qos: .background).async {
                        self?.doCache(events: events, roomId: roomId)
                    }
                }
            }
        })
    }

    /**
     Do cache events list.
     */
    func doCache(events: [MXEvent], roomId: String) {
        let cachedRoom = CKRoomCacheManager.shared.getStoredRoom(roomId: roomId) ?? CKStoredRoom.init(id: roomId, messages: [])
        events.forEach({ (event) in
            var content = ""
            if let contentData = try?  JSONSerialization.data(withJSONObject: event.content, options: .prettyPrinted) {
                content = String(data: contentData, encoding: String.Encoding.ascii) ?? ""
            }

            let message = CKStoredMessage.init(eventId: event.eventId, roomId: event.roomId, senderId: event.sender, eventType: event.eventType, content: content, isEncrypted: event.isEncrypted)
            if !cachedRoom.messages.contains(where: { $0.eventId == message.eventId }) {
                cachedRoom.messages.append(message)
            }
        })

        CKRoomCacheManager.shared.doCacheRoom(cachedRoom)
    }
}

@objcMembers
public class CKAppManager: NSObject {
    static let shared = CKAppManager()
    private (set) var userPassword: String?
    private (set) var passphrase: String?
    private (set) var apiClient: CKAPIClient!

    private override init() {
        super.init()
        setup()
    }

    func setup() {
        if let account = MXKAccountManager.shared()?.accounts.first {
            self.setup(with: account.mxCredentials, password: nil)
        } else {
            apiClient = CKAPIClient(baseURLString: CKEnvironment.target.serviceURL)
        }
    }

    func setup(with credential: MXCredentials, password: String?) {
        if let pwd = password {
            self.userPassword = pwd
        }
        self.passphrase = (credential.userId != nil) ? (credential.userId! + "COLIAKIP") : credential.userId
        apiClient = CKAPIClient(baseURLString: CKEnvironment.target.serviceURL)
        apiClient.authenticator = {(headers: inout HTTPHeaders, params: inout Parameters) in
            if let accessToken = credential.accessToken {
                headers["Authorization"] = "Bearer \(accessToken)"
            }
        }
        AppDelegate.the()?.observeKeybackupState()
    }

    func updatePassphrase(_ passphrase: String) {
        self.passphrase = passphrase
    }

    func generatedPassphrase() -> String? {
        guard let hashString = self.passphrase, let password = self.userPassword else {
            return nil
        }
        let saltData = CKDeriver.shared.ckSalt.data(using: .utf8)!
        let passPhraseString = password + "COLIAKIP"
        if let derivedKeyData = CKDeriver.shared.pbkdf2SHA1(password: hashString,
                                                            salt: saltData,
                                                            keyByteCount: CKCryptoConfig.keyLength,
                                                            rounds: CKCryptoConfig.round),
            let encryptedPassphrase = CKAES.init(keyData: derivedKeyData)?.encrypt(string: passPhraseString) {
            let base64SaltKey = saltData.base64EncodedString()
            let base64EncryptedPassphrase = encryptedPassphrase.base64EncodedString()
            return "\(base64SaltKey):\(base64EncryptedPassphrase)"
        } else {
            return nil
        }
    }

    func preloadData() {
        // TO-DO
    }

    func preloadStaticData() {
        // TO-DO
    }
    
    func isPasswordAvailable() -> Bool {
        return (self.userPassword != nil)
    }
}

