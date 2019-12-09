//
//  CKCallHistoryDataSource.swift
//  Riot
//
//  Created by ReasonLeveing on 11/20/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

private enum EventTypeCallHistory {
    
    case type               // type of event
    case content            // content of event
    case reason             // response reason call hangup
    
    var value: String {
        switch self {
        case .type:
            return "type"
        case .content:
            return "content"
        case .reason:
            return "reason"
        }
    }
    
    static let inviteTimeout = "invite_timeout" // flag check miss call
}

struct CallHistoryModel {
    
    var room: MXRoom
    
    var event: MXEvent!
    
    var decryptedEventContent: [String: Any]!
    
    var isMissCall: Bool = false
}

extension CallHistoryModel {
    
    static func == (lhs: CallHistoryModel, rhs: CallHistoryModel) -> Bool {
        return true
    }
}

@objc public class CKCallHistoryDataSource: RecentsDataSource {
    
    
}


extension CKCallHistoryDataSource {

    func getListCallHistory(completion: (([CallHistoryModel]) -> Void)) {
        
        let searchRooms = self.mxSession.rooms
        
        var filteredEvents: [CallHistoryModel] = []
        
        for room in searchRooms {
            guard let roomId = room.roomId else { return }
            
            if let cachedRoom = CKRoomCacheManager.shared.getStoredRoom(roomId: roomId) {
                
                let messages = cachedRoom.messages.compactMap { $0.copy() as? CKStoredMessage }
                
                let revertMessage = messages.reversed() // loop last message to first
                
                for element in revertMessage {
                    
                    if let event = self.mxSession.store.event(withEventId: element.eventId, inRoom: element.roomId),
                        let coppiedEvent = MXEvent.init(fromJSON: event.jsonDictionary()) {
                        
                        let decryptedEvent = self.decryptedEvent(event: coppiedEvent)
                        
                        if let eventType = decryptedEvent[EventTypeCallHistory.type.value] as? String,
//                            eventType == kMXEventTypeStringCallInvite ||
//                                eventType == kMXEventTypeStringCallAnswer ||
                                eventType == kMXEventTypeStringCallHangup {
                            
                            var isMissCall: Bool = false
                            
                            if let contentEvent = decryptedEvent[EventTypeCallHistory.content.value] as? [String: Any] {
                                isMissCall = self.checkMissCall(format: contentEvent)
                            }
                            
                            let model = CallHistoryModel(room: room,
                                                         event: coppiedEvent,
                                                         decryptedEventContent: decryptedEvent,
                                                         isMissCall: isMissCall)
                            
                            filteredEvents.append(model)
                        }
                        
                    } else {
//                        print("CKCallHistoryDataSource: Don't cast event")
                    }
                }
            }
        }
        
        filteredEvents.sort { (first, second) -> Bool in
            return first.event.age < second.event.age
        }
        
        completion(filteredEvents)
    }
}

extension CKCallHistoryDataSource {
    
    /**
     Extract event content form an event.
     - parameters:
     - event: an item of MXEvent
     */
    private func getEventContent(event: MXEvent) -> [String: Any] {
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
    
    
    private func checkMissCall(format: [String: Any]) -> Bool {
        
        guard let reason = format[EventTypeCallHistory.reason.value] as? String else {
            return false
        }
        
        return reason == EventTypeCallHistory.inviteTimeout
    }
    
    
    private func decryptedEvent(event: MXEvent) -> [String: Any] {
           var eventResult: [String: Any] = [:]

           if event.isEncrypted {
               if let clearEvent = try? self.mxSession.crypto?.decryptEvent(event, inTimeline: nil).clearEvent,
                   let content = clearEvent as? [String: Any] {
                   eventResult = content
               } else if let content = event.content {
                   eventResult = content
               }
           } else {
//               if let content = event.content {
//                   eventResult = content
//               }
           }
        
           return eventResult
       }
}
