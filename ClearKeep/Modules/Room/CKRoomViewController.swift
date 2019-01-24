//
//  CKRoomViewController.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/4/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation
import MatrixKit

@objc final class CKRoomViewController: MXKRoomViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var previewHeaderContainer: UIView!
    @IBOutlet weak var previewHeaderContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var mentionListTableView: UITableView!
    @IBOutlet weak var mentionListTableViewHeightConstraint: NSLayoutConstraint!
    
    // MARK: - Override
    
    public override class func nib() -> UINib? {
        return UINib.init(
            nibName: String(describing: CKRoomViewController.self),
            bundle: Bundle(for: self))
    }

    // MARK: - Properties
    
    /**
     Force the display of the expanded header.
     The default value is NO: this expanded header is hidden on new instantiated RoomViewController object.
     
     When this property is YES, the expanded header is forced each time the view controller appears.
     */
    @objc public var showExpandedHeader = false

    /**
     Preview data for a room invitation received by email, or a link to a room.
     */
    @objc private(set) var roomPreviewData: RoomPreviewData?
    
    // The customized room data source for Vector
    var customizedRoomDataSource: CKRoomDataSource?
    
    // The list of unknown devices that prevent outgoing messages from being sent

    var unknownDevices: MXUsersDevicesMap<MXDeviceInfo>?
    
    // Homeserver notices
    
    var serverNotices: MXServerNotices?
    
    // mentionDataSource
    
    var mentionDataSource: CKMentionDataSource? {
        didSet {
            self.mentionListTableView?.dataSource = mentionDataSource
            self.mentionListTableView?.delegate = mentionDataSource
            
            if mentionDataSource != nil {
                self.mentionListTableView.isHidden = false
                self.mentionListTableView?.reloadData()
                self.mentionListTableViewHeightConstraint.constant = self.mentionListTableView.contentSize.height
                self.mentionListTableView.layoutIfNeeded()
            } else {
                self.mentionListTableView.isHidden = true
            }
        }
    }
}

extension CKRoomViewController {
    
    // MARK: - LifeCycle
    
    override func destroy() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.mxEventDidChangeSentState, object: nil)
        super.destroy()
    }
    
    override func finalizeInit() {
        super.finalizeInit()

        // Listen to the event sent state changes
        NotificationCenter.default.addObserver(self, selector: #selector(self.eventDidChangeSentState(_:)), name: NSNotification.Name.mxEventDidChangeSentState, object: nil)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register first customized cell view classes used to render bubbles
        bubblesTableView.register(RoomIncomingTextMsgBubbleCell.self, forCellReuseIdentifier: RoomIncomingTextMsgBubbleCell.defaultReuseIdentifier())
        bubblesTableView.register(RoomIncomingTextMsgWithoutSenderInfoBubbleCell.self, forCellReuseIdentifier: RoomIncomingTextMsgWithoutSenderInfoBubbleCell.defaultReuseIdentifier())
        bubblesTableView.register(RoomIncomingTextMsgWithPaginationTitleBubbleCell.self, forCellReuseIdentifier: RoomIncomingTextMsgWithPaginationTitleBubbleCell.defaultReuseIdentifier())
        bubblesTableView.register(RoomIncomingAttachmentBubbleCell.self, forCellReuseIdentifier: RoomIncomingAttachmentBubbleCell.defaultReuseIdentifier())
        bubblesTableView.register(RoomIncomingAttachmentWithoutSenderInfoBubbleCell.self, forCellReuseIdentifier: RoomIncomingAttachmentWithoutSenderInfoBubbleCell.defaultReuseIdentifier())
        bubblesTableView.register(RoomIncomingAttachmentWithPaginationTitleBubbleCell.self, forCellReuseIdentifier: RoomIncomingAttachmentWithPaginationTitleBubbleCell.defaultReuseIdentifier())
        bubblesTableView.register(RoomIncomingTextMsgWithoutSenderNameBubbleCell.self, forCellReuseIdentifier: RoomIncomingTextMsgWithoutSenderNameBubbleCell.defaultReuseIdentifier())
        bubblesTableView.register(RoomIncomingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.self, forCellReuseIdentifier: RoomIncomingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.defaultReuseIdentifier())
        
        bubblesTableView.register(RoomIncomingEncryptedTextMsgBubbleCell.self, forCellReuseIdentifier: RoomIncomingEncryptedTextMsgBubbleCell.defaultReuseIdentifier())
        bubblesTableView.register(RoomIncomingEncryptedTextMsgWithoutSenderInfoBubbleCell.self, forCellReuseIdentifier: RoomIncomingEncryptedTextMsgWithoutSenderInfoBubbleCell.defaultReuseIdentifier())
        bubblesTableView.register(RoomIncomingEncryptedTextMsgWithPaginationTitleBubbleCell.self, forCellReuseIdentifier: RoomIncomingEncryptedTextMsgWithPaginationTitleBubbleCell.defaultReuseIdentifier())
        bubblesTableView.register(RoomIncomingEncryptedAttachmentBubbleCell.self, forCellReuseIdentifier: RoomIncomingEncryptedAttachmentBubbleCell.defaultReuseIdentifier())
        bubblesTableView.register(RoomIncomingEncryptedAttachmentWithoutSenderInfoBubbleCell.self, forCellReuseIdentifier: RoomIncomingEncryptedAttachmentWithoutSenderInfoBubbleCell.defaultReuseIdentifier())
        bubblesTableView.register(RoomIncomingEncryptedAttachmentWithPaginationTitleBubbleCell.self, forCellReuseIdentifier: RoomIncomingEncryptedAttachmentWithPaginationTitleBubbleCell.defaultReuseIdentifier())
        bubblesTableView.register(RoomIncomingEncryptedTextMsgWithoutSenderNameBubbleCell.self, forCellReuseIdentifier: RoomIncomingEncryptedTextMsgWithoutSenderNameBubbleCell.defaultReuseIdentifier())
        bubblesTableView.register(RoomIncomingEncryptedTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.self, forCellReuseIdentifier: RoomIncomingEncryptedTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.defaultReuseIdentifier())
        
        bubblesTableView.register(RoomOutgoingAttachmentBubbleCell.self, forCellReuseIdentifier: RoomOutgoingAttachmentBubbleCell.defaultReuseIdentifier())
        bubblesTableView.register(RoomOutgoingAttachmentWithoutSenderInfoBubbleCell.self, forCellReuseIdentifier: RoomOutgoingAttachmentWithoutSenderInfoBubbleCell.defaultReuseIdentifier())
        bubblesTableView.register(RoomOutgoingAttachmentWithPaginationTitleBubbleCell.self, forCellReuseIdentifier: RoomOutgoingAttachmentWithPaginationTitleBubbleCell.defaultReuseIdentifier())
        bubblesTableView.register(RoomOutgoingTextMsgBubbleCell.self, forCellReuseIdentifier: RoomOutgoingTextMsgBubbleCell.defaultReuseIdentifier())
        bubblesTableView.register(RoomOutgoingTextMsgWithoutSenderInfoBubbleCell.self, forCellReuseIdentifier: RoomOutgoingTextMsgWithoutSenderInfoBubbleCell.defaultReuseIdentifier())
        bubblesTableView.register(RoomOutgoingTextMsgWithPaginationTitleBubbleCell.self, forCellReuseIdentifier: RoomOutgoingTextMsgWithPaginationTitleBubbleCell.defaultReuseIdentifier())
        bubblesTableView.register(RoomOutgoingTextMsgWithoutSenderNameBubbleCell.self, forCellReuseIdentifier: RoomOutgoingTextMsgWithoutSenderNameBubbleCell.defaultReuseIdentifier())
        bubblesTableView.register(RoomOutgoingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.self, forCellReuseIdentifier: RoomOutgoingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.defaultReuseIdentifier())
        
        bubblesTableView.register(RoomOutgoingEncryptedAttachmentBubbleCell.self, forCellReuseIdentifier: RoomOutgoingEncryptedAttachmentBubbleCell.defaultReuseIdentifier())
        bubblesTableView.register(RoomOutgoingEncryptedAttachmentWithoutSenderInfoBubbleCell.self, forCellReuseIdentifier: RoomOutgoingEncryptedAttachmentWithoutSenderInfoBubbleCell.defaultReuseIdentifier())
        bubblesTableView.register(RoomOutgoingEncryptedAttachmentWithPaginationTitleBubbleCell.self, forCellReuseIdentifier: RoomOutgoingEncryptedAttachmentWithPaginationTitleBubbleCell.defaultReuseIdentifier())
        bubblesTableView.register(RoomOutgoingEncryptedTextMsgBubbleCell.self, forCellReuseIdentifier: RoomOutgoingEncryptedTextMsgBubbleCell.defaultReuseIdentifier())
        bubblesTableView.register(RoomOutgoingEncryptedTextMsgWithoutSenderInfoBubbleCell.self, forCellReuseIdentifier: RoomOutgoingEncryptedTextMsgWithoutSenderInfoBubbleCell.defaultReuseIdentifier())
        bubblesTableView.register(RoomOutgoingEncryptedTextMsgWithPaginationTitleBubbleCell.self, forCellReuseIdentifier: RoomOutgoingEncryptedTextMsgWithPaginationTitleBubbleCell.defaultReuseIdentifier())
        bubblesTableView.register(RoomOutgoingEncryptedTextMsgWithoutSenderNameBubbleCell.self, forCellReuseIdentifier: RoomOutgoingEncryptedTextMsgWithoutSenderNameBubbleCell.defaultReuseIdentifier())
        bubblesTableView.register(RoomOutgoingEncryptedTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.self, forCellReuseIdentifier: RoomOutgoingEncryptedTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.defaultReuseIdentifier())
        
        bubblesTableView.register(RoomEmptyBubbleCell.self, forCellReuseIdentifier: RoomEmptyBubbleCell.defaultReuseIdentifier())
        
        bubblesTableView.register(RoomMembershipBubbleCell.self, forCellReuseIdentifier: RoomMembershipBubbleCell.defaultReuseIdentifier())
        bubblesTableView.register(RoomMembershipWithPaginationTitleBubbleCell.self, forCellReuseIdentifier: RoomMembershipWithPaginationTitleBubbleCell.defaultReuseIdentifier())
        bubblesTableView.register(RoomMembershipCollapsedBubbleCell.self, forCellReuseIdentifier: RoomMembershipCollapsedBubbleCell.defaultReuseIdentifier())
        bubblesTableView.register(RoomMembershipCollapsedWithPaginationTitleBubbleCell.self, forCellReuseIdentifier: RoomMembershipCollapsedWithPaginationTitleBubbleCell.defaultReuseIdentifier())
        bubblesTableView.register(RoomMembershipExpandedBubbleCell.self, forCellReuseIdentifier: RoomMembershipExpandedBubbleCell.defaultReuseIdentifier())
        bubblesTableView.register(RoomMembershipExpandedWithPaginationTitleBubbleCell.self, forCellReuseIdentifier: RoomMembershipExpandedWithPaginationTitleBubbleCell.defaultReuseIdentifier())
        
        bubblesTableView.register(RoomSelectedStickerBubbleCell.self, forCellReuseIdentifier: RoomSelectedStickerBubbleCell.defaultReuseIdentifier())
        bubblesTableView.register(RoomPredecessorBubbleCell.self, forCellReuseIdentifier: RoomPredecessorBubbleCell.defaultReuseIdentifier())
        
        // Mention tableview
        mentionListTableView.register(CKMentionUserTableViewCell.nib(), forCellReuseIdentifier: CKMentionUserTableViewCell.defaultReuseIdentifier())
        
        // Replace the default input toolbar view.
        // Note: this operation will force the layout of subviews. That is why cell view classes must be registered before.
        updateRoomInputToolbarViewClassIfNeeded()
        
        // Refresh tool bar if the room data source is set.
        if roomDataSource != nil {
            refreshRoomInputToolbar()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    @objc func eventDidChangeSentState(_ notif: Notification?) {
        // We are only interested by event that has just failed in their encryption
        // because of unknown devices in the room
        let event = notif?.object as? MXEvent
        if event?.sentState == MXEventSentStateFailed
            && (event?.roomId == roomDataSource.roomId)
            && (event?.sentError._domain == MXEncryptingErrorDomain)
            && event?.sentError._code == Int(MXEncryptingErrorUnknownDeviceCode.rawValue)
            && unknownDevices == nil {
            
            dismissTemporarySubViews()
            
            // List all unknown devices
            unknownDevices = MXUsersDevicesMap()
            
            let outgoingMsgs: [MXEvent] = roomDataSource.room?.outgoingMessages() ?? []
            for event: MXEvent in outgoingMsgs {
                if event.sentState == MXEventSentStateFailed && (event.sentError._domain == MXEncryptingErrorDomain) && event.sentError._code == Int(MXEncryptingErrorUnknownDeviceCode.rawValue) {
                    let eventUnknownDevices = (event.sentError as NSError?)?.userInfo[MXEncryptingErrorUnknownDeviceDevicesKey]
                    unknownDevices?.addEntries(from: eventUnknownDevices as? MXUsersDevicesMap<AnyObject>)
                }
            }
            
            //-- CK: force resending all unsent messages
            mainSession.crypto.setDevicesKnown(unknownDevices, complete: { [weak self] in
                
                self?.unknownDevices = nil
                self?.stopActivityIndicator()
                
                // And resend pending messages
                self?.resendAllUnsentMessages()
            })
        }
    }
    
    func resendAllUnsentMessages() {
        // List unsent event ids
        let outgoingMsgs = roomDataSource.room.outgoingMessages() ?? []
        var failedEventIds = [AnyHashable](repeating: 0, count: outgoingMsgs.count)

        for event in outgoingMsgs {
            if event.sentState == MXEventSentStateFailed {
                failedEventIds.append(event.eventId)
            }
        }

        // Launch iterative operation
        resendFailedEvent(0, inArray: failedEventIds)
    }

    func resendFailedEvent(_ index: Int, inArray failedEventIds: [Any]?) {
        if index < (failedEventIds?.count ?? 0) {
            let failedEventId = failedEventIds?[index] as? String
            let nextIndex: Int = index + 1

            // Let the datasource resend. It will manage local echo, etc.
            roomDataSource.resendEvent(withEventId: failedEventId, success: { eventId in

                self.resendFailedEvent(nextIndex, inArray: failedEventIds)

            }, failure: { error in

                self.resendFailedEvent(nextIndex, inArray: failedEventIds)

            })

            return
        }

        // Refresh activities view
        refreshActivitiesViewDisplay()
    }

    func listenToServerNotices() {
        if serverNotices == nil {
            serverNotices = MXServerNotices(matrixSession: roomDataSource.mxSession)
            serverNotices?.delegate = self
        }
    }

    func isRoomPreview() -> Bool {
        // Check first whether some preview data are defined.
        if roomPreviewData != nil {
            return true
        }

        if roomDataSource != nil && roomDataSource.state == MXKDataSourceStateReady && roomDataSource.room.summary.membership == MXMembership.invite {
            return true
        }

        return false
    }

    // MARK: Input Tool Bar
    
    // Set the input toolbar according to the current display
    func updateRoomInputToolbarViewClassIfNeeded() {
        var roomInputToolbarViewClass: AnyClass? = CKRoomInputToolbarView.self

        // Check the user has enough power to post message
        if roomDataSource?.roomState != nil {
            let powerLevels: MXRoomPowerLevels? = roomDataSource.roomState.powerLevels
            let userPowerLevel: Int? = powerLevels?.powerLevelOfUser(withUserID: mainSession.myUser.userId)

            let canSend: Bool = (userPowerLevel ?? 0) >= powerLevels?.__minimumPowerLevelForSendingEvent(asMessage: kMXEventTypeStringRoomMessage) ?? 0
            let isRoomObsolete: Bool = roomDataSource.roomState.isObsolete
            let isResourceLimitExceeded: Bool = roomDataSource.mxSession?.syncError?.errcode == kMXErrCodeStringResourceLimitExceeded

            if isRoomObsolete || isResourceLimitExceeded {
                roomInputToolbarViewClass = nil
            } else if !canSend {
                roomInputToolbarViewClass = DisabledRoomInputToolbarView.self
            }
        }
        
        // Do not show toolbar in case of preview
        if isRoomPreview() {
            roomInputToolbarViewClass = nil
        }

        // Change inputToolbarView class only if given class is different from current one
        if inputToolbarView == nil {
            super.setRoomInputToolbarViewClass(roomInputToolbarViewClass)
            updateInputToolBarViewHeight()
        } else {
            if roomInputToolbarViewClass == nil {
                super.setRoomInputToolbarViewClass(nil)
                updateInputToolBarViewHeight()
            } else {
                if !inputToolbarView.isMember(of: roomInputToolbarViewClass!) {
                    super.setRoomInputToolbarViewClass(roomInputToolbarViewClass!)
                    updateInputToolBarViewHeight()
                }
            }
        }
    }
    
    func updateInputToolBarViewHeight() {
        // Update the inputToolBar height.
        let height = inputToolbarHeight()
        // Disable animation during the update
        UIView.setAnimationsEnabled(false)
        roomInputToolbarView(inputToolbarView, heightDidChanged: height) { (_) in
            //
        }
        UIView.setAnimationsEnabled(true)
    }

    // Get the height of the current room input toolbar
    func inputToolbarHeight() -> CGFloat {
        var height: CGFloat = 0

        if (inputToolbarView is CKRoomInputToolbarView) {
            height = (inputToolbarView as? CKRoomInputToolbarView)?.mainToolbarMinHeightConstraint.constant ?? 0.0
        } else if (inputToolbarView is DisabledRoomInputToolbarView) {
            height = (inputToolbarView as? DisabledRoomInputToolbarView)?.mainToolbarMinHeightConstraint.constant ?? 0.0
        }

        return height
    }
    
    func refreshRoomInputToolbar() {
        let userPictureView: MXKImageView?

        if inputToolbarView != nil && (inputToolbarView is CKRoomInputToolbarView) {
            let roomInputToolbarView = inputToolbarView as! CKRoomInputToolbarView
                        
        } else if inputToolbarView != nil && (inputToolbarView is DisabledRoomInputToolbarView) {
            let roomInputToolbarView = inputToolbarView as! DisabledRoomInputToolbarView

            // Get user picture view in input toolbar
            userPictureView = roomInputToolbarView.pictureView

            // For the moment, there is only one reason to use `DisabledRoomInputToolbarView`
            roomInputToolbarView.setDisabledReason(NSLocalizedString("room_do_not_have_permission_to_post", tableName: "Vector", bundle: Bundle.main, value: "", comment: ""))
        }

    }
    
    func refreshRoomTitle() {
        // TODO: implement
    }
    
    // MARK: - Unreachable Network Handling
    
    func refreshActivitiesViewDisplay() {
        // TODO: implement
    }

    // MARK: - Preview
    @objc func displayRoomPreview(_ previewData: RoomPreviewData?) {
        // Release existing room data source or preview

        // Release existing room data source or preview
        displayRoom(nil)

        if previewData != nil {
            self.isEventsAcknowledgementEnabled = false

            addMatrixSession(previewData!.mxSession)

            roomPreviewData = previewData

            refreshRoomTitle()

            if let roomDataSource = roomPreviewData?.roomDataSource {
                super.displayRoom(roomDataSource)
            }
        }
    }
    
    // MARK: - Override MXKRoomViewController
    override func onMatrixSessionChange() {
        super.onMatrixSessionChange()

        // Re-enable the read marker display, and disable its update.
        roomDataSource.showReadMarker = true
        updateRoomReadMarker = false
    }
    
    override func onRoomDataSourceReady() {
        // Handle here invitation
        if roomDataSource.room.summary.membership == MXMembership.invite {
            navigationItem.rightBarButtonItem?.isEnabled = false
        } else {
            super.onRoomDataSourceReady()
        }
    }


    override func displayRoom(_ dataSource: MXKRoomDataSource?) {
        // Remove potential preview Data
        if roomPreviewData != nil {
            roomPreviewData = nil
            removeMatrixSession(mainSession)
        }

        // Enable the read marker display, and disable its update.
        dataSource?.showReadMarker = true
        updateRoomReadMarker = false

        super.displayRoom(dataSource)
        
        customizedRoomDataSource = nil
        
        if self.roomDataSource != nil
        {
            self.listenToServerNotices()
            
            self.isEventsAcknowledgementEnabled = true

            // Set room title view
            self.refreshRoomTitle()
            
            // Store ref on customized room data source
            if dataSource?.isKind(of: CKRoomDataSource.self) == true {
                customizedRoomDataSource = dataSource as? CKRoomDataSource
            }
        }
        else
        {
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }
    
    // MARK: - MXKDataSourceDelegate
    override func cellViewClass(for cellData: MXKCellData!) -> MXKCellRendering.Type! {
        var cellViewClass: MXKCellRendering.Type!
        let isEncryptedRoom = roomDataSource.room.summary.isEncrypted
        
        // Sanity check
        if let bubbleData = cellData as? MXKRoomBubbleCellDataStoring {
            
            // Select the suitable table view cell class, by considering first the empty bubble cell.
            if bubbleData.hasNoDisplay {
                cellViewClass = RoomEmptyBubbleCell.self
            } else if bubbleData.tag == RoomBubbleCellDataTag.roomCreateWithPredecessor.rawValue {
                cellViewClass = RoomPredecessorBubbleCell.self
            } else if bubbleData.tag == RoomBubbleCellDataTag.membership.rawValue {
                if bubbleData.collapsed {
                    if bubbleData.nextCollapsableCellData != nil {
                        cellViewClass = bubbleData.isPaginationFirstBubble ? RoomMembershipCollapsedWithPaginationTitleBubbleCell.self : RoomMembershipCollapsedBubbleCell.self
                    } else {
                        // Use a normal membership cell for a single membership event
                        cellViewClass = bubbleData.isPaginationFirstBubble ? RoomMembershipWithPaginationTitleBubbleCell.self : RoomMembershipBubbleCell.self
                    }
                } else if bubbleData.collapsedAttributedTextMessage != nil {
                    // The cell (and its series) is not collapsed but this cell is the first
                    // of the series. So, use the cell with the "collapse" button.
                    cellViewClass = bubbleData.isPaginationFirstBubble ? RoomMembershipExpandedWithPaginationTitleBubbleCell.self : RoomMembershipExpandedBubbleCell.self
                } else {
                    cellViewClass = bubbleData.isPaginationFirstBubble ? RoomMembershipWithPaginationTitleBubbleCell.self : RoomMembershipBubbleCell.self
                }
            } else if bubbleData.isIncoming {
                if bubbleData.isAttachmentWithThumbnail {
                    // Check whether the provided celldata corresponds to a selected sticker
                    if customizedRoomDataSource?.selectedEventId != nil && (bubbleData.attachment.type == MXKAttachmentTypeSticker) && (bubbleData.attachment.eventId == customizedRoomDataSource?.selectedEventId) {
                        cellViewClass = RoomSelectedStickerBubbleCell.self
                    } else if bubbleData.isPaginationFirstBubble {
                        cellViewClass = isEncryptedRoom ? RoomIncomingEncryptedAttachmentWithPaginationTitleBubbleCell.self : RoomIncomingAttachmentWithPaginationTitleBubbleCell.self
                    } else if bubbleData.shouldHideSenderInformation {
                        cellViewClass = isEncryptedRoom ? RoomIncomingEncryptedAttachmentWithoutSenderInfoBubbleCell.self : RoomIncomingAttachmentWithoutSenderInfoBubbleCell.self
                    } else {
                        cellViewClass = isEncryptedRoom ? RoomIncomingEncryptedAttachmentBubbleCell.self : RoomIncomingAttachmentBubbleCell.self
                    }
                } else {
                    if bubbleData.isPaginationFirstBubble {
                        if bubbleData.shouldHideSenderName {
                            cellViewClass = isEncryptedRoom ? RoomIncomingEncryptedTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.self : RoomIncomingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.self
                        } else {
                            cellViewClass = isEncryptedRoom ? RoomIncomingEncryptedTextMsgWithPaginationTitleBubbleCell.self : RoomIncomingTextMsgWithPaginationTitleBubbleCell.self
                        }
                    } else if bubbleData.shouldHideSenderInformation {
                        cellViewClass = isEncryptedRoom ? RoomIncomingEncryptedTextMsgWithoutSenderInfoBubbleCell.self : RoomIncomingTextMsgWithoutSenderInfoBubbleCell.self
                    } else if bubbleData.shouldHideSenderName {
                        cellViewClass = isEncryptedRoom ? RoomIncomingEncryptedTextMsgWithoutSenderNameBubbleCell.self : RoomIncomingTextMsgWithoutSenderNameBubbleCell.self
                    } else {
                        cellViewClass = isEncryptedRoom ? RoomIncomingEncryptedTextMsgBubbleCell.self : RoomIncomingTextMsgBubbleCell.self
                    }
                }
            } else {
                // Handle here outgoing bubbles
                if bubbleData.isAttachmentWithThumbnail {
                    // Check whether the provided celldata corresponds to a selected sticker
                    if customizedRoomDataSource?.selectedEventId != nil && (bubbleData.attachment.type == MXKAttachmentTypeSticker) && (bubbleData.attachment.eventId == customizedRoomDataSource?.selectedEventId) {
                        cellViewClass = RoomSelectedStickerBubbleCell.self
                    } else if bubbleData.isPaginationFirstBubble {
                        cellViewClass = isEncryptedRoom ? RoomOutgoingEncryptedAttachmentWithPaginationTitleBubbleCell.self : RoomOutgoingAttachmentWithPaginationTitleBubbleCell.self
                    } else if bubbleData.shouldHideSenderInformation {
                        cellViewClass = isEncryptedRoom ? RoomOutgoingEncryptedAttachmentWithoutSenderInfoBubbleCell.self : RoomOutgoingAttachmentWithoutSenderInfoBubbleCell.self
                    } else {
                        cellViewClass = isEncryptedRoom ? RoomOutgoingEncryptedAttachmentBubbleCell.self : RoomOutgoingAttachmentBubbleCell.self
                    }
                } else {
                    if bubbleData.isPaginationFirstBubble {
                        if bubbleData.shouldHideSenderName {
                            cellViewClass = isEncryptedRoom ? RoomOutgoingEncryptedTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.self : RoomOutgoingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.self
                        } else {
                            cellViewClass = isEncryptedRoom ? RoomOutgoingEncryptedTextMsgWithPaginationTitleBubbleCell.self : RoomOutgoingTextMsgWithPaginationTitleBubbleCell.self
                        }
                    } else if bubbleData.shouldHideSenderInformation {
                        cellViewClass = isEncryptedRoom ? RoomOutgoingEncryptedTextMsgWithoutSenderInfoBubbleCell.self : RoomOutgoingTextMsgWithoutSenderInfoBubbleCell.self
                    } else if bubbleData.shouldHideSenderName {
                        cellViewClass = isEncryptedRoom ? RoomOutgoingEncryptedTextMsgWithoutSenderNameBubbleCell.self : RoomOutgoingTextMsgWithoutSenderNameBubbleCell.self
                    } else {
                        cellViewClass = isEncryptedRoom ? RoomOutgoingEncryptedTextMsgBubbleCell.self : RoomOutgoingTextMsgBubbleCell.self
                    }
                }
            }
        }
        
        return cellViewClass
    }
    
    override func mention(_ roomMember: MXRoomMember!) {
        let memberName = roomMember.displayname.count > 0 ? roomMember.displayname : roomMember.userId

        if (roomMember.userId == mainSession.myUser.userId) {
            inputToolbarView.pasteText("me ")
        } else {
            inputToolbarView.pasteText("\(memberName ?? "") ")
        }
    }
}

// MARK: - MXServerNoticesDelegate

extension CKRoomViewController: MXServerNoticesDelegate {
    func serverNoticesDidChangeState(_ serverNotices: MXServerNotices?) {
        refreshActivitiesViewDisplay()
    }
}

// MARK: - CKRoomInputToolbarViewDelegate

extension CKRoomViewController: CKRoomInputToolbarViewDelegate {
    func roomInputToolbarView(_ toolbarView: MXKRoomInputToolbarView?, triggerMention: Bool, mentionText: String?) {
        if triggerMention {
            
            var roomMembers: [MXRoomMember] = self.roomDataSource?.roomState.members.members ?? []
            if let mentionText = mentionText,
                mentionText.count > 0 {
                roomMembers = self.roomDataSource?.roomState.members.members.filter({ $0.displayname.contains(mentionText) == true }) ?? []
            }
            
            if roomMembers.count > 0 {
                mentionDataSource = CKMentionDataSource.init(roomMembers, matrixSession: self.mainSession, delegate: self)
                return
            }
        }
        
        if mentionDataSource != nil {
            mentionDataSource = nil
        }
    }
}

extension CKRoomViewController: CKMentionDataSourceDelegate {
    func mentionDataSource(_ dataSource: CKMentionDataSource, didSelect member: MXRoomMember) {
        self.mention(member)
        mentionDataSource = nil
    }
}
