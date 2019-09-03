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
    
    // time sent messages
    var timeSent = ""
    
    
    /**
     Tell whether the initial event of the timeline (if any) must be marked. Default is NO.
     */
    @objc var markTimelineInitialEvent = false

    /**
     The data for the cells served by `MXKRoomDataSource`.
     */
    private var bubbles: [RoomBubbleCellData] {
        get {
            // -- fixbug CK 296, cast optional object
            guard let bubbles = self.value(forKey: "bubbles") as? [RoomBubbleCellData] else {
                return []
            }
            return bubbles
        }
        set {
            self.setValue(bubbles, forKey: "bubbles")
        }
    }
    
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
        
        // Do the processing on the same processing queue as MXKRoomDataSource
        MXKRoomDataSource.processingQueue()?.async {
            // Remove the previous displayed read receipt for each user who sent a
            // new read receipt.
            // To implement it, we need to find the sender id of each new read receipt
            // among the read receipts array of all events in all bubbles.

            let readReceiptSenders = receiptEvent?.readReceiptSenders() as? [String]
            let lockQueue = DispatchQueue(label: "bubbles")
            lockQueue.sync {
                for cellData in self.bubbles {
                    var updatedCellDataReadReceipts: [String /* eventId */ : [MXReceiptData]] = [:]
                    let eventIds = cellData.readReceipts.allKeys as? [String]
                    
                    for eventId in (eventIds ?? []) {
                        let receiptDatas = cellData.readReceipts?[eventId] as? [MXReceiptData]
                        
                        for receiptData in (receiptDatas ?? []) {
                            for senderId in (readReceiptSenders ?? []) {
                                if (receiptData.userId == senderId) {
                                    if updatedCellDataReadReceipts[eventId] != nil {
                                        if let readReceipts = cellData.readReceipts[eventId] {
                                            updatedCellDataReadReceipts[eventId] = readReceipts as? [MXReceiptData]
                                        }
                                    }

                                    updatedCellDataReadReceipts[eventId] = updatedCellDataReadReceipts[eventId]?.filter({ $0.userId != receiptData.userId })
                                    break
                                }
                            }
                        }
                    }

                    // Flush found changed to the cell data
                    for eventId in (eventIds ?? []) {
                        if (updatedCellDataReadReceipts[eventId] ?? []).count != 0 {
                            cellData.readReceipts[eventId] = updatedCellDataReadReceipts[eventId]
                        } else {
                            cellData.readReceipts[eventId] = nil
                        }
                    }
                }
            }
        }
        
        // Update cell data we have received a read receipt for
        let readEventIds = receiptEvent?.readReceiptEventIds() as? [String]
        for eventId in (readEventIds ?? []) {
            if let cellData = cellDataOfEvent(withEventId: eventId) as? RoomBubbleCellData {
                let lockQueue = DispatchQueue(label: "bubbles")
                lockQueue.sync {
                    if !cellData.hasNoDisplay {
                        cellData.readReceipts[eventId] = room.getEventReceipts(eventId, sorted: true)
                    } else {
                        // Ignore the read receipts on the events without an actual display.
                        cellData.readReceipts[eventId] = nil
                    }
                }
            }
        }

        DispatchQueue.main.async {
            super.didReceiveReceiptEvent(receiptEvent, roomState: roomState)
        }
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
                var index = bubbles.count - 1
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
        
        // Finalize cell view customization here
        if let bubbleCell = cell as? MXKRoomBubbleTableViewCell {
            
            let cellData = bubbleCell.bubbleData as? RoomBubbleCellData
            let bubbleComponents = cellData?.bubbleComponents
            
            // Display time for each message
            if bubbleCell.bubbleInfoContainer != nil {
                bubbleCell.addDateLabel(true)
            }
            
            let isCollapsableCellCollapsed: Bool = cellData?.collapsable != nil && cellData?.collapsed != nil

            // Display timestamp of the last message
            if cellData?.containsLastMessage != nil && !isCollapsableCellCollapsed {
                bubbleCell.addTimestampLabel(forComponent: cellData?.mostRecentComponentIndex.magnitude ?? UInt(NSNotFound))
            }

            // Handle read receipts and read marker display.
            // Ignore the read receipts on the bubble without actual display.
            // Ignore the read receipts on collapsed bubbles
            if (self.showBubbleReceipts && (cellData?.readReceipts.count ?? 0) > 0 && !isCollapsableCellCollapsed)
                || showReadMarker {
                
                // Read receipts container are inserted here on the right side into the content view.
                // Some vertical whitespaces are added in message text view (see RoomBubbleCellData class) to insert correctly multiple receipts.

                var index = (bubbleComponents?.count ?? 0) - 1
                var bottomPositionY: CGFloat = bubbleCell.frame.size.height
                
                while index >= 0 {
                    let component = bubbleComponents![index]
                    
                    if component.event?.sentState != MXEventSentStateFailed {
                        // Handle read receipts (if any)
                        if showBubbleReceipts
                            && (cellData?.readReceipts.count ?? 0) > 0
                            && !isCollapsableCellCollapsed {
                            
                            // Get the events receipts by ignoring the current user receipt.
                            let receipts = cellData?.readReceipts[component.event.eventId] as? [MXReceiptData]
                            var roomMembers: [MXRoomMember] = []
                            var placeholders: [UIImage] = []
                            
                            // Check whether some receipts are found
                            if (receipts ?? []).count > 0 {
                                // Retrieve the corresponding room members

                                for data in receipts! {
                                    let roomMember: MXRoomMember? = roomState.members.member(withUserId: data.userId)
                                    if let roomMember = roomMember {
                                        roomMembers.append(roomMember)
                                        placeholders.append(AvatarGenerator.generateAvatar(forMatrixItem: roomMember.userId, withDisplayName: roomMember.displayname))
                                    }
                                }
                            }
                            
                            // Check whether some receipts are found
                            if roomMembers.count > 0 {
                                // Define the read receipts container, positioned on the right border of the bubble cell (Note the right margin 6 pts).
                                let avatarsContainer = MXKReceiptSendersContainer(frame: CGRect(x: bubbleCell.frame.size.width - 156, y: bottomPositionY - 13, width: 150, height: 12), andMediaManager: mxSession.mediaManager)

                                // Custom avatar display
                                avatarsContainer?.maxDisplayedAvatars = 5
                                avatarsContainer?.avatarMargin = 6

                                // Set the container tag to be able to retrieve read receipts container from component index (see component selection in MXKRoomBubbleTableViewCell (Vector) category).
                                avatarsContainer?.tag = index

                                avatarsContainer?.refreshReceiptSenders(roomMembers, withPlaceHolders: placeholders, andAlignment: ReadReceiptsAlignment.receiptAlignmentRight)
                                avatarsContainer?.readReceipts = receipts
                                
                                let tapRecognizer = UITapGestureRecognizer(target: bubbleCell, action: #selector(bubbleCell.onReceiptContainerTap(_:)))
                                tapRecognizer.numberOfTapsRequired = 1
                                tapRecognizer.numberOfTouchesRequired = 1
                                avatarsContainer?.addGestureRecognizer(tapRecognizer)
                                avatarsContainer?.isUserInteractionEnabled = true

                                avatarsContainer?.translatesAutoresizingMaskIntoConstraints = false
                                avatarsContainer?.accessibilityIdentifier = "readReceiptsContainer"

                                // Add this read receipts container in the content view
                                if bubbleCell.tmpSubviews == nil {
                                    if let avatarsContainer = avatarsContainer {
                                        bubbleCell.tmpSubviews = NSMutableArray.init(object: avatarsContainer)
                                    } else {
                                        bubbleCell.tmpSubviews = NSMutableArray.init()
                                    }
                                } else {
                                    if let avatarsContainer = avatarsContainer {
                                        bubbleCell.tmpSubviews!.add(avatarsContainer)
                                    }
                                }
                                
                                if let avatarsContainer = avatarsContainer {
                                    bubbleCell.contentView.addSubview(avatarsContainer)
                                    
                                    // Force receipts container size
                                    let widthConstraint = NSLayoutConstraint(item: avatarsContainer, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 150)
                                    let heightConstraint = NSLayoutConstraint(item: avatarsContainer, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 12)
                                    
                                    // Force receipts container position
                                    
                                    let trailingConstraint = NSLayoutConstraint(item: avatarsContainer, attribute: .trailing, relatedBy: .equal, toItem: avatarsContainer.superview, attribute: .trailing, multiplier: 1.0, constant: -6)
                                    let topConstraint = NSLayoutConstraint(item: avatarsContainer, attribute: .top, relatedBy: .equal, toItem: avatarsContainer.superview, attribute: .top, multiplier: 1.0, constant: bottomPositionY - 13)
                                    
                                    // Available on iOS 8 and later
                                    NSLayoutConstraint.activate([widthConstraint, heightConstraint, topConstraint, trailingConstraint])
                                }
                            }
                        }
                        
                        // Check whether the read marker must be displayed here.
                        if self.showReadMarker {
                            // The read marker is added into the overlay container.
                            // CAUTION: Keep disabled the user interaction on this container to not disturb tap gesture handling.
                            bubbleCell.bubbleOverlayContainer.backgroundColor = UIColor.clear
                            bubbleCell.bubbleOverlayContainer.alpha = 1
                            bubbleCell.bubbleOverlayContainer.isUserInteractionEnabled = false
                            bubbleCell.bubbleOverlayContainer.isHidden = false

                            if component.event.eventId == self.room.accountData.readMarkerEventId {
                                bubbleCell.readMarkerView = UIView(frame: CGRect(x: 0, y: bottomPositionY - 2, width: bubbleCell.bubbleOverlayContainer.frame.size.width, height: 2))
                                bubbleCell.readMarkerView.backgroundColor = kRiotColorGreen
                                // Hide by default the marker, it will be shown and animated when the cell will be rendered.
                                bubbleCell.readMarkerView.isHidden = true
                                bubbleCell.readMarkerView.tag = index

                                bubbleCell.readMarkerView.translatesAutoresizingMaskIntoConstraints = false
                                bubbleCell.readMarkerView.accessibilityIdentifier = "readMarker"
                                bubbleCell.bubbleOverlayContainer.addSubview(bubbleCell.readMarkerView)

                                // Force read marker constraints
                                bubbleCell.readMarkerViewTopConstraint = NSLayoutConstraint(item: bubbleCell.readMarkerView, attribute: .top, relatedBy: .equal, toItem: bubbleCell.bubbleOverlayContainer, attribute: .top, multiplier: 1.0, constant: bottomPositionY - 2)
                                bubbleCell.readMarkerViewLeadingConstraint = NSLayoutConstraint(item: bubbleCell.readMarkerView, attribute: .leading, relatedBy: .equal, toItem: bubbleCell.bubbleOverlayContainer, attribute: .leading, multiplier: 1.0, constant: 0)

                                bubbleCell.readMarkerViewTrailingConstraint = NSLayoutConstraint(item: bubbleCell.bubbleOverlayContainer, attribute: .trailing, relatedBy: .equal, toItem: bubbleCell.readMarkerView, attribute: .trailing, multiplier: 1.0, constant: 0)
                                bubbleCell.readMarkerViewHeightConstraint = NSLayoutConstraint(item: bubbleCell.readMarkerView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 2)

                                NSLayoutConstraint.activate([
                                    bubbleCell.readMarkerViewTopConstraint,
                                    bubbleCell.readMarkerViewLeadingConstraint,
                                    bubbleCell.readMarkerViewTrailingConstraint,
                                    bubbleCell.readMarkerViewHeightConstraint
                                ])

                            }
                        }
                    }
                    
                    // Prepare the bottom position for the next read receipt container (if any)
                    bottomPositionY = (bubbleCell.msgTextViewTopConstraint?.constant ?? 0) + component.position.y;
                    
                    index -= 1
                }
            }
            
            // Check whether an event is currently selected: the other messages are then blurred
            if let selectedEventId = selectedEventId, selectedEventId.count > 0 {
                // Check whether the selected event belongs to this bubble
                if let selectedComponentIndex = cellData?.selectedComponentIndex {
                    bubbleCell.selectComponent(UInt(selectedComponentIndex))
                } else {
                    bubbleCell.blurred = true
                }
            }

            // Reset the marker if any
            if bubbleCell.markerView != nil {
                bubbleCell.markerView?.removeFromSuperview()
            }

            // Manage initial event (case of permalink or search result)
            if timeline?.initialEventId != nil && markTimelineInitialEvent {
                // Check if the cell contains this initial event
                
                for (index, component) in (bubbleComponents ?? []).enumerated() {
                    if (component.event.eventId == timeline.initialEventId) {
                        // If yes, mark the event
                        bubbleCell.markComponent(UInt(index))
                        break
                    }
                }
            }

            // Auto animate the sticker in case of animated gif
            bubbleCell.isAutoAnimatedGif = cellData?.attachment != nil && cellData?.attachment.type == MXKAttachmentTypeSticker
            
            // Disable textview selecting
//            bubbleCell.messageTextView?.isSelectable = false
        }
 
        return cell
    }
    
    override func cellData(at index: Int) -> MXKRoomBubbleCellDataStoring! {
        if index < bubbles.count {
            
            let bubbleData = self.bubbles[index]
            let components = bubbleData.bubbleComponents ?? []
            
            // CK-34: Remove unnecessary chat content
            components.forEach { (component) in
                if let event = component.event {
                    
                    if CKMessageContentManagement.shouldHideMessage(from: event, inRoomState: self.roomState) {
                        bubbleData.removeEvent(event.eventId)
                    }
                }
            }
            
            if (bubbleData.events?.count ?? 0) == 0 { return nil }
            return bubbleData
        }

        return nil
    }
}
