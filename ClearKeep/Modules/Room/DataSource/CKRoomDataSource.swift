//
//  CKRoomDataSource.swift
//  Riot
//
//  Created by Pham Hoa on 1/21/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

class CKRoomDataSource: MXKRoomDataSource {
    /**
     The event id of the current selected event if any. Default is nil.
     */

    var selectedEventId: String? = nil {
        didSet {
            // Cancel the current selection (if any)
            if selectedEventId != nil {
                let cellData: RoomBubbleCellData? = cellDataOfEvent(withEventId: selectedEventId) as? RoomBubbleCellData
                cellData?.selectedEventId = nil
            }

            if let selectedEventId = selectedEventId, selectedEventId.count > 0 {
                let cellData: RoomBubbleCellData? = cellDataOfEvent(withEventId: selectedEventId) as? RoomBubbleCellData

                if cellData?.collapsed != nil && cellData?.nextCollapsableCellData != nil {
                    // Select nothing for a collased cell but open it
                    collapseRoomBubble(cellData, collapsed: false)
                    return
                } else {
                    cellData?.selectedEventId = selectedEventId
                }
            }
        }
    }
    
    /**
     Tell whether the initial event of the timeline (if any) must be marked. Default is NO.
     */
    @objc var markTimelineInitialEvent = false

    /**
     The data for the cells served by `MXKRoomDataSource`.
     */
    var bubbles: [RoomBubbleCellData] = []
    
    private var kRiotDesignValuesDidChangeThemeNotificationObserver: Any?
    
    override func destroy() {
        if (kRiotDesignValuesDidChangeThemeNotificationObserver != nil) {
            NotificationCenter.default.removeObserver(kRiotDesignValuesDidChangeThemeNotificationObserver!)
            kRiotDesignValuesDidChangeThemeNotificationObserver = nil
        }
        
        super.destroy()
    }
    
    override init() {
        super.init()
    }
    
    override init(roomId: String?, andMatrixSession matrixSession: MXSession?) {
        super.init(roomId: roomId, andMatrixSession: matrixSession)
        
        // Replace default Cell data class
        registerCellDataClass(RoomBubbleCellData.self, forCellIdentifier: kMXKRoomBubbleCellDataIdentifier)
        
        // Replace the event formatter
        updateEventFormatter()
        
        // Handle timestamp and read receips display at Vector app level (see [tableView: cellForRowAtIndexPath:])
        useCustomDateTimeLabel = true
        useCustomReceipts = true
        useCustomUnsentButton = true
        
        // Set bubble pagination
        bubblesPagination = MXKRoomDataSourceBubblesPaginationPerDay
        
        markTimelineInitialEvent = false
        
        // Observe user interface theme change.
        kRiotDesignValuesDidChangeThemeNotificationObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.riotDesignValuesDidChangeTheme, object: nil, queue: OperationQueue.main, using: { notif in
            
            // Force room data reload.
            self.updateEventFormatter()
            self.reload()
            
        })
        
    }
    
    override func finalizeInitialization() {
        super.finalizeInitialization()
        
        // Sadly, we need to make sure we have fetched all room members from the HS
        // to be able to display read receipts
        if !mxSession.store.hasLoadedAllRoomMembers(forRoom: roomId) {
            room?.members({ (roomMembers) in
                print("[MXKRoomDataSource] finalizeRoomDataSource: All room members have been retrieved")
                
                // Refresh the full table
                self.delegate?.dataSource(self, didCellChange: nil)
            }, lazyLoadedMembers: { (_) in
                //
            }, failure: { (error) in
                print("[MXKRoomDataSource] finalizeRoomDataSource: Cannot retrieve all room members")
            })
        }
    }
    
    func updateEventFormatter() {
        // Set a new event formatter
        // TODO: We should use the same EventFormatter instance for all the rooms of a mxSession.
        eventFormatter = EventFormatter(matrixSession: mxSession)
        eventFormatter.treatMatrixUserIdAsLink = true
        eventFormatter.treatMatrixRoomIdAsLink = true
        eventFormatter.treatMatrixRoomAliasAsLink = true
        eventFormatter.treatMatrixGroupIdAsLink = true
        
        // Apply the event types filter to display only the wanted event types.
        eventFormatter.eventTypesFilterForMessages = MXKAppSettings.standard().eventsFilterForMessages
    }
    
    override func didReceiveReceiptEvent(_ receiptEvent: MXEvent?, roomState: MXRoomState?) {
        super.didReceiveReceiptEvent(receiptEvent, roomState: roomState)
    }

    
    /**
     Check if there is an active jitsi widget in the room and return it.

     @return a widget representating the active jitsi conference in the room. Else, nil.
     */
    func jitsiWidget() -> Widget? {
        var jitsiWidget: Widget?

        // Note: Manage only one jitsi widget at a time for the moment
        jitsiWidget = WidgetManager.shared().widgets(ofTypes: [kWidgetTypeJitsi], in: room, with: roomState).first

        return jitsiWidget
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count: Int = super.tableView(tableView, numberOfRowsInSection: section)
        
        if count != 0 {
            // Enable the containsLastMessage flag for the cell data which contains the last message.
            let lockQueue = DispatchQueue(label: "bubbles")
            lockQueue.sync {
                // Reset first all cell data
                for cellData in bubbles {
                    cellData.containsLastMessage = false
                }
                
                // The cell containing the last message is the last one with an actual display.
                var index = bubbles.count
                while index > 0 {
                    let cellData: RoomBubbleCellData? = bubbles[index]
                    if cellData?.attributedTextMessage != nil {
                        cellData?.containsLastMessage = true
                        break
                    }
                    index -= 1
                }
            }
        }
        
        return count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Do cell data customization that needs to be done before [MXKRoomBubbleTableViewCell render]
        let roomBubbleCellData: RoomBubbleCellData? = self.cellData(at: indexPath.row) as? RoomBubbleCellData
        
        // Use the Riot style placeholder
        if roomBubbleCellData?.senderAvatarPlaceholder == nil {
            roomBubbleCellData?.senderAvatarPlaceholder = AvatarGenerator.generateAvatar(forMatrixItem: roomBubbleCellData?.senderId, withDisplayName: roomBubbleCellData?.senderDisplayName)
        }
        
        let cell: UITableViewCell = super.tableView(tableView, cellForRowAt: indexPath)
        
        
        return cell
    }

}
