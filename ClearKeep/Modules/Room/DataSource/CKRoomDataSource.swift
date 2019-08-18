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

    var selectedEventId: String? {
        willSet {
            // Cancel the current selection (if any)ss
            if self.selectedEventId != nil {
                let cellData: RoomBubbleCellData? = cellDataOfEvent(withEventId: selectedEventId) as? RoomBubbleCellData
                cellData?.selectedEventId = nil
                cellData?.showTimestampForSelectedComponent = false
            }
            
            if let selectedEventId = newValue, selectedEventId.count > 0 {
                let cellData: RoomBubbleCellData? = cellDataOfEvent(withEventId: selectedEventId) as? RoomBubbleCellData
                
                cellData?.showTimestampForSelectedComponent = self.showBubbleDateTimeOnSelection ?? true
                
                if cellData?.collapsed != nil && cellData?.nextCollapsableCellData != nil {
                    // Select nothing for a collased cell but open it
                    collapseRoomBubble(cellData, collapsed: false)
                    return
                } else {
                    cellData?.selectedEventId = selectedEventId
                }
            }
            
            self.selectedEventId = newValue
        } 
    }
    
    // time sent messages
    var timeSent = ""
    
    /**
     Tell whether timestamp should be displayed on event selection. Default is YES.
     */
    var showBubbleDateTimeOnSelection: Bool?
    
    /**
     Tell whether the initial event of the timeline (if any) must be marked. Default is NO.
     */
    @objc var markTimelineInitialEvent = false

    /**
     The data for the cells served by `MXKRoomDataSource`.
     */
    private var bubbles: [RoomBubbleCellData] {
        get {
            return self.value(forKey: "bubbles") as! [RoomBubbleCellData]
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
        
        self.showBubbleDateTimeOnSelection = true
        self.showReactions = true
        
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
    
    override func updateCellDataReactions(_ cellData: MXKRoomBubbleCellDataStoring!, forEventId eventId: String!) {
        super.updateCellDataReactions(cellData, forEventId: eventId)
        
        self.setNeedsUpdateAdditionalContentHeightForCellData(cellData)
    }
    
    override func update(_ cellData: MXKRoomBubbleCellData!, withReadReceipts readReceipts: [MXReceiptData]!, forEventId eventId: String!) {
        super.update(cellData, withReadReceipts: readReceipts, forEventId: eventId)
        
        self.setNeedsUpdateAdditionalContentHeightForCellData(cellData)
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
        let roomBubbleCellData = self.cellData(at: indexPath.row) as? RoomBubbleCellData
        if roomBubbleCellData?.senderAvatarPlaceholder == nil {
            roomBubbleCellData?.senderAvatarPlaceholder = AvatarGenerator.generateAvatar(forMatrixItem: roomBubbleCellData?.senderId, withDisplayName: roomBubbleCellData?.senderDisplayName)
        }
        
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        // Finalize cell view customization here
        if let bubbleCell = cell as? MXKRoomBubbleTableViewCell {
            let cellData = bubbleCell.bubbleData as? RoomBubbleCellData
            let bubbleComponents = cellData?.bubbleComponents
            
            let isCollapsableCellCollapsed = cellData?.collapsable ?? false && cellData?.collapsed ?? false
            
            // Display timestamp of the last message
            if cellData?.containsLastMessage != nil && !isCollapsableCellCollapsed {
                bubbleCell.addTimestampLabel(forComponent: UInt(cellData?.mostRecentComponentIndex ?? 0))
            }
            
            let temporaryViews = NSMutableArray()
            
            // Handle read receipts and read marker display.
            // Ignore the read receipts on the bubble without actual display.
            // Ignore the read receipts on collapsed bubbles
            if ((((self.showBubbleReceipts && ((cellData?.readReceipts?.count) != nil)) || ((cellData?.reactions?.count) != nil)) && !isCollapsableCellCollapsed) || self.showReadMarker) {
                // Read receipts container are inserted here on the right side into the content view.
                // Some vertical whitespaces are added in message text view (see RoomBubbleCellData class) to insert correctly multiple receipts.
                
                for (index, component) in (bubbleComponents ?? []).enumerated() {
                    let componentEventId = component.event.eventId ?? ""
                    
                    if component.event.sentState != MXEventSentStateFailed {
                        var bottomPositionY: CGFloat = 0
                        
                        let bubbleComponentFrame = bubbleCell.componentFrameInContentView(for: index)
                        
                        if !bubbleComponentFrame.equalTo(CGRect.null) {
                            bottomPositionY = bubbleComponentFrame.origin.y + bubbleComponentFrame.size.height;
                        } else {
                            continue
                        }
                        
                        var reactionsView: BubbleReactionsView?
                        debugPrint("[CKRoomDataSource] reactions \(cellData?.readReceipts?.count ?? -1)")
                        if let reactions = cellData?.reactions?[componentEventId] as? MXAggregatedReactions, !isCollapsableCellCollapsed {
                            let showAllReactions = cellData?.showAllReactions(forEvent: componentEventId) ?? false
                            let bubbleReactionsViewModel = BubbleReactionsViewModel(aggregatedReactions: reactions, eventId: componentEventId, showAll: showAllReactions)
                            
                            reactionsView = BubbleReactionsView()
                            reactionsView?.viewModel = bubbleReactionsViewModel
                            reactionsView?.updateTheme()
                            
                            temporaryViews.add(reactionsView!)
                            bubbleReactionsViewModel.viewModelDelegate = self
                            
                            reactionsView?.translatesAutoresizingMaskIntoConstraints = false
                            bubbleCell.contentView.addSubview(reactionsView!)
                            
                            if bubbleCell.tmpSubviews == nil {
                                bubbleCell.tmpSubviews = NSMutableArray()
                            }
                            
                            var leftMargin = RoomBubbleCellLayout.reactionsViewLeftMargin;
                            if self.room.summary.isEncrypted {
                                leftMargin += RoomBubbleCellLayout.encryptedContentLeftMargin;
                            }
                            
                            bubbleCell.tmpSubviews?.add(reactionsView!)
                            
                            // Force receipts container position
                            let leadingConstraint = NSLayoutConstraint(item: reactionsView!, attribute: .leading, relatedBy: .equal, toItem: reactionsView?.superview, attribute: .leading, multiplier: 1.0, constant: leftMargin)
                            let trailingConstraint = NSLayoutConstraint(item: reactionsView!, attribute: .trailing, relatedBy: .equal, toItem: reactionsView?.superview, attribute: .trailing, multiplier: 1.0, constant: -RoomBubbleCellLayout.reactionsViewRightMargin)
                            let topConstraint = NSLayoutConstraint(item: reactionsView!, attribute: .top, relatedBy: .equal, toItem: reactionsView?.superview, attribute: .top, multiplier: 1.0, constant: bottomPositionY + RoomBubbleCellLayout.reactionsViewTopMargin)
                            
                            // Available on iOS 8 and later
                            NSLayoutConstraint.activate([leadingConstraint, trailingConstraint, topConstraint])
                        }
                        
                        var avatarsContainer: MXKReceiptSendersContainer?
                        
                        // Handle read receipts (if any)
                        debugPrint("[CKRoomDataSource] readReceipts \(cellData?.readReceipts?.count ?? -1)")
                        if self.showBubbleReceipts && (cellData?.readReceipts?.count != nil) && !isCollapsableCellCollapsed {
                            
                            // Get the events receipts by ignoring the current user receipt.
                            var roomMembers: [MXRoomMember] = []
                            var placeholders: [UIImage] = []
                            
                            // Check whether some receipts are found
                            if let receipts = cellData?.readReceipts[component.event.eventId] as? [MXReceiptData], receipts.count > 0 {
                                // Retrieve the corresponding room members
                                for receipt in receipts {
                                    let roomMember: MXRoomMember? = roomState.members.member(withUserId: receipt.userId)
                                    if let roomMember = roomMember {
                                        roomMembers.append(roomMember)
                                        placeholders.append(AvatarGenerator.generateAvatar(forMatrixItem: roomMember.userId, withDisplayName: roomMember.displayname))
                                    }
                                }
                                
                                // Define the read receipts container, positioned on the right border of the bubble cell (Note the right margin 6 pts).
                                avatarsContainer = MXKReceiptSendersContainer(frame: CGRect(x: bubbleCell.frame.size.width - RoomBubbleCellLayout.readReceiptsViewWidth + RoomBubbleCellLayout.readReceiptsViewRightMargin, y: bottomPositionY + RoomBubbleCellLayout.readReceiptsViewTopMargin, width: RoomBubbleCellLayout.readReceiptsViewWidth, height: RoomBubbleCellLayout.readReceiptsViewHeight), andMediaManager: self.mxSession.mediaManager)
                                        
                                // Custom avatar display
                                avatarsContainer?.maxDisplayedAvatars = 5
                                avatarsContainer?.avatarMargin = 6
                                
                                // Set the container tag to be able to retrieve read receipts container from component index (see component selection in MXKRoomBubbleTableViewCell (Vector) category).
                                avatarsContainer?.tag = index;
                                
                                avatarsContainer?.moreLabelTextColor = themeService.attrs.textPrimaryColor
                                
                                avatarsContainer?.refreshReceiptSenders(roomMembers, withPlaceHolders: placeholders, andAlignment: ReadReceiptsAlignment.receiptAlignmentRight)
                                avatarsContainer?.readReceipts = receipts
                                let tapRecognizer = UITapGestureRecognizer(target: bubbleCell, action: #selector(bubbleCell.onReceiptContainerTap(_:)))
                                tapRecognizer.numberOfTapsRequired = 1
                                tapRecognizer.numberOfTouchesRequired = 1
                                avatarsContainer?.addGestureRecognizer(tapRecognizer)
                                avatarsContainer?.isUserInteractionEnabled = true
 
                                avatarsContainer?.translatesAutoresizingMaskIntoConstraints = false
                                avatarsContainer?.accessibilityIdentifier = "readReceiptsContainer"
                                
                                temporaryViews.add(avatarsContainer!)
                                
                                // Add this read receipts container in the content view
                                if bubbleCell.tmpSubviews == nil {
                                    bubbleCell.tmpSubviews = NSMutableArray.init(object: [avatarsContainer!])
                                } else {
                                    bubbleCell.tmpSubviews?.add(avatarsContainer!)
                                }
                                bubbleCell.contentView.addSubview(avatarsContainer!)
                                
                                // Force receipts container size
                                let widthConstraint = NSLayoutConstraint(item: avatarsContainer!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: RoomBubbleCellLayout.readReceiptsViewWidth)
                                let heightConstraint = NSLayoutConstraint(item: avatarsContainer!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: RoomBubbleCellLayout.readReceiptsViewHeight)
                                
                                // Force receipts container position
                                
                                let trailingConstraint = NSLayoutConstraint(item: avatarsContainer!, attribute: .trailing, relatedBy: .equal, toItem: avatarsContainer?.superview, attribute: .trailing, multiplier: 1.0, constant: -RoomBubbleCellLayout.readReceiptsViewRightMargin)
                                
                                // At the bottom, we have reactions or nothing
                                var topConstraint = NSLayoutConstraint()
                                if reactionsView != nil {
                                    topConstraint = NSLayoutConstraint(item: avatarsContainer!, attribute: .top, relatedBy: .equal, toItem: reactionsView?.superview, attribute: .bottom, multiplier: 1.0, constant: RoomBubbleCellLayout.readReceiptsViewTopMargin)
                                } else {
                                    topConstraint = NSLayoutConstraint(item: avatarsContainer!, attribute: .top, relatedBy: .equal, toItem: avatarsContainer?.superview, attribute: .top, multiplier: 1.0, constant: bottomPositionY + RoomBubbleCellLayout.readReceiptsViewTopMargin)
                                }
                                
                                // Available on iOS 8 and later
                                NSLayoutConstraint.activate([widthConstraint, heightConstraint, topConstraint, trailingConstraint])
                            }
                        }
                        
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
                }
            }
            
            // Update attachmentView bottom constraint to display reactions and read receipts if needed
            let attachmentView = bubbleCell.attachmentView
            let attachmentViewBottomConstraint = bubbleCell.attachViewBottomConstraint
            
            if attachmentView != nil && temporaryViews.count > 0 {
                attachmentViewBottomConstraint?.constant = roomBubbleCellData?.additionalContentHeight ?? 0
            } else if attachmentView != nil {
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
            if (bubbleCell.markerView != nil) {
                bubbleCell.markerView.removeFromSuperview()
            }
            
            // Manage initial event (case of permalink or search result)
            if timeline?.initialEventId != nil && self.markTimelineInitialEvent {
                // Check if the cell contains this initial event
                
                for (index, component) in (bubbleComponents ?? []).enumerated() {
                    if component.event.eventId == self.timeline.initialEventId {
                        // If yes, mark the event
                        bubbleCell.markComponent(UInt(index))
                        break
                    }
                }
            }
            
            // Auto animate the sticker in case of animated gif
            bubbleCell.isAutoAnimatedGif = cellData?.attachment != nil && cellData?.attachment.type == MXKAttachmentTypeSticker
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
    
    func sendVideo(_ videoLocalURL: URL, success: @escaping (_ eventId: String?) -> Void, failure: @escaping (_ error: Error?) -> Void) {
        let videoThumbnail: UIImage? = MXKVideoThumbnailGenerator.shared.generateThumbnail(from: videoLocalURL)
        sendVideo(videoLocalURL, withThumbnail: videoThumbnail, success: success, failure: failure)
    }
    
    func setNeedsUpdateAdditionalContentHeightForCellData(_ cellData: MXKRoomBubbleCellDataStoring) {
        if let roomBubbleCellData = cellData as? RoomBubbleCellData {
            roomBubbleCellData.setNeedsUpdateAdditionalContentHeight()
        }
    }
    
}

// MARK: - BubbleReactionsViewModelDelegate
extension CKRoomDataSource: BubbleReactionsViewModelDelegate {
    
    func bubbleReactionsViewModel(_ viewModel: BubbleReactionsViewModel, didAddReaction reactionCount: MXReactionCount, forEventId eventId: String) {
        self.addReaction(reactionCount.reaction, forEventId: eventId, success: {
            
        }) { error in
            
        }
    }
    
    func bubbleReactionsViewModel(_ viewModel: BubbleReactionsViewModel, didRemoveReaction reactionCount: MXReactionCount, forEventId eventId: String) {
        self.removeReaction(reactionCount.reaction, forEventId: eventId, success: {
            
        }) { error in
            
        }
    }
    
    func bubbleReactionsViewModel(_ viewModel: BubbleReactionsViewModel, didShowAllTappedForEventId eventId: String) {
        self.setShowAllReactions(true, forEvent: eventId)
    }
    
    func bubbleReactionsViewModel(_ viewModel: BubbleReactionsViewModel, didShowLessTappedForEventId eventId: String) {
        self.setShowAllReactions(false, forEvent: eventId)
    }
    
    private func setShowAllReactions(_ showAllReactions: Bool, forEvent eventId: String?) {
        weak var cellData = cellDataOfEvent(withEventId: eventId)
        if (cellData is RoomBubbleCellData) {
            let roomBubbleCellData = cellData as? RoomBubbleCellData
            
            roomBubbleCellData?.setShowAllReactions(showAllReactions, forEvent: eventId)
            updateCellDataReactions(roomBubbleCellData, forEventId: eventId)
            
            delegate.dataSource(self, didCellChange: nil)
        }
    }
}
