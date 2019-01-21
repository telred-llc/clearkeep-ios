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
    
    @IBOutlet weak var previewHeaderContainer: UIView!
    @IBOutlet weak var previewHeaderContainerHeightConstraint: NSLayoutConstraint!
    
    public override class func nib() -> UINib? {
        return UINib.init(
            nibName: String(describing: CKRoomViewController.self),
            bundle: Bundle(for: self))
    }

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
}

extension CKRoomViewController {
    
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

        for event: MXEvent in outgoingMsgs {
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

    // MARK: - Unreachable Network Handling

    func refreshActivitiesViewDisplay() {
        // TODO: implement
    }
    
    func listenToServerNotices() {
        if serverNotices == nil {
            serverNotices = MXServerNotices(matrixSession: roomDataSource.mxSession)
            serverNotices?.delegate = self
        }
    }
    
    // MARK: - Preview
     @objc func displayRoomPreview(_ previewData: RoomPreviewData?) {
        // Release existing room data source or preview

        // Release existing room data source or preview
        displayRoom(nil)

        if previewData != nil {
//            eventsAcknowledgementEnabled = false

            addMatrixSession(previewData!.mxSession)

            roomPreviewData = previewData

//            refreshRoomTitle()

            if let roomDataSource = roomPreviewData?.roomDataSource {
                super.displayRoom(roomDataSource)
            }
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
    
    func refreshRoomTitle() {
        // TODO: implement
    }
    
    // MARK: - MXKDataSourceDelegate
    override func cellViewClass(for cellData: MXKCellData!) -> MXKCellRendering.Type! {
        var cellViewClass: MXKCellRendering.Type!
        let isEncryptedRoom = roomDataSource.room.summary.isEncrypted
        
        // Sanity check
        if cellData is MXKRoomBubbleCellDataStoring {
            let bubbleData = cellData as? MXKRoomBubbleCellDataStoring
            
            // Select the suitable table view cell class, by considering first the empty bubble cell.
            if bubbleData?.hasNoDisplay != nil {
                cellViewClass = RoomEmptyBubbleCell.self
            } else if bubbleData?.tag == RoomBubbleCellDataTag.roomCreateWithPredecessor.rawValue {
                cellViewClass = RoomPredecessorBubbleCell.self
            } else if bubbleData?.tag == RoomBubbleCellDataTag.membership.rawValue {
                if bubbleData?.collapsed != nil {
                    if bubbleData?.nextCollapsableCellData != nil {
                        cellViewClass = bubbleData?.isPaginationFirstBubble != nil ? RoomMembershipCollapsedWithPaginationTitleBubbleCell.self : RoomMembershipCollapsedBubbleCell.self
                    } else {
                        // Use a normal membership cell for a single membership event
                        cellViewClass = bubbleData?.isPaginationFirstBubble != nil ? RoomMembershipWithPaginationTitleBubbleCell.self : RoomMembershipBubbleCell.self
                    }
                } else if bubbleData?.collapsedAttributedTextMessage != nil {
                    // The cell (and its series) is not collapsed but this cell is the first
                    // of the series. So, use the cell with the "collapse" button.
                    cellViewClass = bubbleData?.isPaginationFirstBubble != nil ? RoomMembershipExpandedWithPaginationTitleBubbleCell.self : RoomMembershipExpandedBubbleCell.self
                } else {
                    cellViewClass = bubbleData?.isPaginationFirstBubble != nil ? RoomMembershipWithPaginationTitleBubbleCell.self : RoomMembershipBubbleCell.self
                }
            } else if bubbleData?.isIncoming != nil {
                if bubbleData?.isAttachmentWithThumbnail != nil {
                    // Check whether the provided celldata corresponds to a selected sticker
                    if customizedRoomDataSource?.selectedEventId != nil && (bubbleData?.attachment.type == MXKAttachmentTypeSticker) && (bubbleData?.attachment.eventId == customizedRoomDataSource?.selectedEventId) {
                        cellViewClass = RoomSelectedStickerBubbleCell.self
                    } else if bubbleData?.isPaginationFirstBubble != nil {
                        cellViewClass = isEncryptedRoom ? RoomIncomingEncryptedAttachmentWithPaginationTitleBubbleCell.self : RoomIncomingAttachmentWithPaginationTitleBubbleCell.self
                    } else if bubbleData?.shouldHideSenderInformation != nil {
                        cellViewClass = isEncryptedRoom ? RoomIncomingEncryptedAttachmentWithoutSenderInfoBubbleCell.self : RoomIncomingAttachmentWithoutSenderInfoBubbleCell.self
                    } else {
                        cellViewClass = isEncryptedRoom ? RoomIncomingEncryptedAttachmentBubbleCell.self : RoomIncomingAttachmentBubbleCell.self
                    }
                } else {
                    if bubbleData?.isPaginationFirstBubble != nil {
                        if bubbleData?.shouldHideSenderName != nil {
                            cellViewClass = isEncryptedRoom ? RoomIncomingEncryptedTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.self : RoomIncomingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.self
                        } else {
                            cellViewClass = isEncryptedRoom ? RoomIncomingEncryptedTextMsgWithPaginationTitleBubbleCell.self : RoomIncomingTextMsgWithPaginationTitleBubbleCell.self
                        }
                    } else if bubbleData?.shouldHideSenderInformation != nil {
                        cellViewClass = isEncryptedRoom ? RoomIncomingEncryptedTextMsgWithoutSenderInfoBubbleCell.self : RoomIncomingTextMsgWithoutSenderInfoBubbleCell.self
                    } else if bubbleData?.shouldHideSenderName != nil {
                        cellViewClass = isEncryptedRoom ? RoomIncomingEncryptedTextMsgWithoutSenderNameBubbleCell.self : RoomIncomingTextMsgWithoutSenderNameBubbleCell.self
                    } else {
                        cellViewClass = isEncryptedRoom ? RoomIncomingEncryptedTextMsgBubbleCell.self : RoomIncomingTextMsgBubbleCell.self
                    }
                }
            } else {
                // Handle here outgoing bubbles
                if bubbleData?.isAttachmentWithThumbnail != nil {
                    // Check whether the provided celldata corresponds to a selected sticker
                    if customizedRoomDataSource?.selectedEventId != nil && (bubbleData?.attachment.type == MXKAttachmentTypeSticker) && (bubbleData?.attachment.eventId == customizedRoomDataSource?.selectedEventId) {
                        cellViewClass = RoomSelectedStickerBubbleCell.self
                    } else if bubbleData?.isPaginationFirstBubble != nil {
                        cellViewClass = isEncryptedRoom ? RoomOutgoingEncryptedAttachmentWithPaginationTitleBubbleCell.self : RoomOutgoingAttachmentWithPaginationTitleBubbleCell.self
                    } else if bubbleData?.shouldHideSenderInformation != nil {
                        cellViewClass = isEncryptedRoom ? RoomOutgoingEncryptedAttachmentWithoutSenderInfoBubbleCell.self : RoomOutgoingAttachmentWithoutSenderInfoBubbleCell.self
                    } else {
                        cellViewClass = isEncryptedRoom ? RoomOutgoingEncryptedAttachmentBubbleCell.self : RoomOutgoingAttachmentBubbleCell.self
                    }
                } else {
                    if bubbleData?.isPaginationFirstBubble != nil {
                        if bubbleData?.shouldHideSenderName != nil {
                            cellViewClass = isEncryptedRoom ? RoomOutgoingEncryptedTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.self : RoomOutgoingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.self
                        } else {
                            cellViewClass = isEncryptedRoom ? RoomOutgoingEncryptedTextMsgWithPaginationTitleBubbleCell.self : RoomOutgoingTextMsgWithPaginationTitleBubbleCell.self
                        }
                    } else if bubbleData?.shouldHideSenderInformation != nil {
                        cellViewClass = isEncryptedRoom ? RoomOutgoingEncryptedTextMsgWithoutSenderInfoBubbleCell.self : RoomOutgoingTextMsgWithoutSenderInfoBubbleCell.self
                    } else if bubbleData?.shouldHideSenderName != nil {
                        cellViewClass = isEncryptedRoom ? RoomOutgoingEncryptedTextMsgWithoutSenderNameBubbleCell.self : RoomOutgoingTextMsgWithoutSenderNameBubbleCell.self
                    } else {
                        cellViewClass = isEncryptedRoom ? RoomOutgoingEncryptedTextMsgBubbleCell.self : RoomOutgoingTextMsgBubbleCell.self
                    }
                }
            }
        }
        
        return cellViewClass
    }
}

extension CKRoomViewController: MXServerNoticesDelegate {
    func serverNoticesDidChangeState(_ serverNotices: MXServerNotices?) {
        refreshActivitiesViewDisplay()
    }
}
