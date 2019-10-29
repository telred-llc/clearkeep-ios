//
//  CKRoomDataSource.swift
//  Riot
//
//  Created by Pham Hoa on 1/21/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

@objc class CKRoomDataSource: MXKRoomDataSource {
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
    
    // Search event message
    @objc var initialEvent: MXEvent?
    
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

        self.initData()
    }
    
    override init(roomId: String?, initialEventId: String?, andMatrixSession matrixSession: MXSession?) {
        super.init(roomId: roomId, initialEventId: initialEventId, andMatrixSession: matrixSession)

        self.initData()
    }
    
    private func initData() {
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
        showReactions = true

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
        var temporaryViews = [Any]()
        // Finalize cell view customization here
        if let bubbleCell = cell as? MXKRoomBubbleTableViewCell {
            
            let cellData = bubbleCell.bubbleData as? RoomBubbleCellData
            let bubbleComponents = cellData?.bubbleComponents
            
            // Display time for each message
            if bubbleCell.bubbleInfoContainer != nil {
                bubbleCell.addDateLabel(true)
            }
            
            var isCollapsableCellCollapsed: Bool = false
            
            if let collapsable = cellData?.collapsable, let collapsed = cellData?.collapsed {
                isCollapsableCellCollapsed = collapsable && collapsed
            }

            // Display timestamp of the last message
            if cellData?.containsLastMessage != nil && !isCollapsableCellCollapsed {
                bubbleCell.addTimestampLabel(forComponent: cellData?.mostRecentComponentIndex.magnitude ?? UInt(NSNotFound))
            }

            // Handle read receipts and read marker display.
            // Ignore the read receipts on the bubble without actual display.
            // Ignore the read receipts on collapsed bubbles
            if (self.showBubbleReceipts && !isCollapsableCellCollapsed) || showReadMarker {
                
                // Read receipts container are inserted here on the right side into the content view.
                // Some vertical whitespaces are added in message text view (see RoomBubbleCellData class) to insert correctly multiple receipts.

                var index = (bubbleComponents?.count ?? 0) - 1
                var bottomPositionY: CGFloat = bubbleCell.frame.size.height
                
                while index >= 0 {
                    let component = bubbleComponents![index]
                    
                    if component.event?.sentState != MXEventSentStateFailed {
                        var reactionsView: BubbleReactionsView?
                        let bubbleComponentFrame = bubbleCell.componentFrameInContentView(for: index)
                        if !bubbleComponentFrame.equalTo(CGRect.null) {
                            bottomPositionY = bubbleComponentFrame.origin.y + bubbleComponentFrame.size.height
                        } else {
                            continue
                        }
                        
                        // Reactions: tiemlv
                        if let reactions = cellData?.reactions, reactions.count > 0 {
                            let componentEventId: String = component.event.eventId
                            let aggregatedReactions: MXAggregatedReactions? = reactions[componentEventId] as? MXAggregatedReactions
                            
                            if (!component.event.isRedactedEvent() && !isCollapsableCellCollapsed && ((aggregatedReactions?.withNonZeroCount()) != nil)) {
                                
                                reactionsView = BubbleReactionsView()
                                let showAllReactions: Bool = cellData?.showAllReactions(forEvent: componentEventId) ?? false
                                let bubbleReactionsViewModel: BubbleReactionsViewModel = BubbleReactionsViewModel(aggregatedReactions: (aggregatedReactions?.withNonZeroCount())!, eventId: componentEventId, showAll: showAllReactions)
                                let bubbleComponentFrame = bubbleCell.componentFrameInContentView(for: index)

                                if !bubbleComponentFrame.equalTo(CGRect.null) {
                                    bottomPositionY = bubbleComponentFrame.origin.y + bubbleComponentFrame.size.height
                                }
                                
                                reactionsView?.viewModel = bubbleReactionsViewModel
                                reactionsView?.update(theme: ThemeService.shared.theme)
                                temporaryViews.append(reactionsView as Any)
                                bubbleReactionsViewModel.viewModelDelegate = self
                                reactionsView?.translatesAutoresizingMaskIntoConstraints = false
                                bubbleCell.contentView.addSubview(reactionsView!)

                                if bubbleCell.tmpSubviews == nil {
                                    bubbleCell.tmpSubviews = []
                                }
                                
                                bubbleCell.tmpSubviews.add(reactionsView!)

                                var leftMargin = RoomBubbleCellLayout.reactionsViewLeftMargin

                                if self.room.summary.isEncrypted {
                                    leftMargin += RoomBubbleCellLayout.encryptedContentLeftMargin
                                }

                                let leadConstraint = NSLayoutConstraint.init(item: reactionsView!, attribute: .leading, relatedBy: .equal, toItem: reactionsView!.superview!, attribute: .leading, multiplier: 1.0, constant: leftMargin)
                                let trailConstraint = NSLayoutConstraint.init(item: reactionsView!, attribute: .trailing, relatedBy: .equal, toItem: reactionsView!.superview!, attribute: .trailing, multiplier: 1.0, constant: -15)
                                let topConstraint = NSLayoutConstraint.init(item: reactionsView!, attribute: .top, relatedBy: .equal, toItem: reactionsView!.superview!, attribute: .top, multiplier: 1.0, constant: bottomPositionY + RoomBubbleCellLayout.reactionsViewTopMargin)

                                NSLayoutConstraint.activate([leadConstraint, trailConstraint, topConstraint])
                            }
                        }
                    }

                    // Prepare the bottom position for the next read receipt container (if any)
//                    bottomPositionY = (bubbleCell.msgTextViewTopConstraint?.constant ?? 0) + component.position.y;
                    
                    index -= 1
                }
            }
            
            // Update attachmentView bottom constraint to display reactions and read receipts if needed
            if let _ = bubbleCell.attachmentView, temporaryViews.count > 0 {
                if let _ = bubbleCell.attachViewBottomConstraint, let data = roomBubbleCellData {
                    bubbleCell.attachViewBottomConstraint.constant = data.additionalContentHeight
                }
            } else if let _ = bubbleCell.attachmentView {
                bubbleCell.resetAttachmentViewBottomConstraintConstant()
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
                    } else if let relateInfo = component.event.relatesTo,
                        relateInfo.eventId == timeline.initialEventId {
                        bubbleCell.markComponent(UInt(index))
                        break
                    }
                }
            }

            // Auto animate the sticker in case of animated gif
            bubbleCell.isAutoAnimatedGif = cellData?.attachment != nil && cellData?.attachment.type == MXKAttachmentTypeSticker
            
            // Disable textview selecting
//            bubbleCell.messageTextView?.isSelectable = false
            
            if bubbleCell.userNameLabel != nil {
                
                bubbleCell.userNameLabel.text = (cellData?.senderDisplayName ?? "").firstName
            }
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

                    if event.eventId == timeline.initialEventId, let newEvent = initialEvent {
                        bubbleData.updateEvent(event.eventId, with: newEvent)
                    }
                }
            }
            
            if (bubbleData.events?.count ?? 0) == 0 { return nil }
            return bubbleData
        }

        return nil
    }
}


// MARK: BubbleReactionsViewModelDelegate
extension CKRoomDataSource {
    
    func setShowAllReactions(_ showAllReactions: Bool, forEvent eventId: String?) {
        weak var cellData = cellDataOfEvent(withEventId: eventId)
        if (cellData is RoomBubbleCellData) {
            let roomBubbleCellData = cellData as? RoomBubbleCellData

            roomBubbleCellData?.setShowAllReactions(showAllReactions, forEvent: eventId)
            updateCellDataReactions(roomBubbleCellData, forEventId: eventId)

            delegate.dataSource(self, didCellChange: nil)
        }
    }
}

extension CKRoomDataSource: BubbleReactionsViewModelDelegate {
    
    func bubbleReactionsViewModel(_ viewModel: BubbleReactionsViewModel, didAddReaction reactionCount: MXReactionCount, forEventId eventId: String) {
        
        addReaction(reactionCount.reaction, forEventId: eventId, success: {
            
        }) { (error) in
//            print("------, "error?.localizedDescription)
        }
    }
    
    func bubbleReactionsViewModel(_ viewModel: BubbleReactionsViewModel, didRemoveReaction reactionCount: MXReactionCount, forEventId eventId: String) {
        
        removeReaction(reactionCount.reaction, forEventId: eventId, success: {
            
        }) { (error) in
//            print("------, "error?.localizedDescription")
        }
    }
    
    func bubbleReactionsViewModel(_ viewModel: BubbleReactionsViewModel, didShowAllTappedForEventId eventId: String) {
        
        setShowAllReactions(true, forEvent: eventId)
    }
    
    func bubbleReactionsViewModel(_ viewModel: BubbleReactionsViewModel, didShowLessTappedForEventId eventId: String) {
        
        setShowAllReactions(false, forEvent: eventId)
    }
    
    func bubbleReactionsViewModel(_ viewModel: BubbleReactionsViewModel, didLongPressForEventId eventId: String) {
        
    }
}
