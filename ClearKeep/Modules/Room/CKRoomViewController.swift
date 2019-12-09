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

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var previewHeaderContainer: UIView!
    @IBOutlet weak var previewHeaderContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var mentionListTableView: UITableView!
    @IBOutlet weak var mentionListTableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var activityCHeight: NSLayoutConstraint!
    @IBOutlet weak var bottomContainerViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var overlayContainerView: UIView!
    @IBOutlet var invitationController: CKRoomInvitationController!

    // MARK: - Constants
    
    private let kShowRoomSearchSegue = "showRoomSearch"
    private let documentPickerPresenter = MXKDocumentPickerPresenter()
    lazy private var queue = DispatchQueue(label: "CKRoomQueue")
    
    // MARK: - Properties
    
    // MARK: Public
    
    
    // Reactions
    var roomContextualMenuViewController: RoomContextualMenuViewController?
    
    var roomContextualMenuPresenter: RoomContextualMenuPresenter?
    
    var emojiPickerCoordinatorBridgePresenter: EmojiPickerCoordinatorBridgePresenter?
    
    var reactionHistoryCoordinatorBridgePresenter: ReactionHistoryCoordinatorBridgePresenter?
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
            self.updateMentionTableView(mentionDataSource: self.mentionDataSource)
        }
    }
    
    // List (id) of members who are typing in the room.

    var currentTypingUsers: [String]?
    
    // Tell whether the input text field is in send reply mode. If true typed message will be sent to highlighted event.

    var isInReplyMode = false
    
    /**
     The potential text input placeholder is saved when it is replaced temporarily
     */
    var savedInputToolbarPlaceholder: String?
    
    /**
     The original message text before being edited
     */
    var textMessageBeforeEditing: String?

    override var keyboardHeight: CGFloat {
        didSet {
            if let inputToolBarView = inputToolbarView as? CKRoomInputToolbarView {
                inputToolBarView.maxNumberOfLines = 2
            }
        }
        
    }
    
    var currentInputView: UIView?
    
    var isPresentPhotoLibrary: Bool = false {
        
        didSet {
            if !isPresentPhotoLibrary {
                currentInputView = nil
                if let toolbarView = inputToolbarView as? CKRoomInputToolbarView {
                    let lastMessage = toolbarView.growingTextView?.text ?? ""
                    toolbarView.typingMessage = .text(msg: lastMessage)
                }
            }
        }
    }
    
    weak var imagePickerController: ImagePickerController?

    // MARK: - ACTION
    
    @IBAction func clickedOnInvitationButton(_ sender: UIButton!) {
        self.invitationController?.clickedOnButton(sender)
    }
    
    // MARK: Private
    
    /**
     Current alert (if any).
     */
    private var currentAlert: UIAlertController? {
        get {
            return self.value(forKey: "currentAlert") as? UIAlertController
        }
        set {
            self.setValue(newValue, forKey: "currentAlert")
        }
    }
    
    // The intermediate action sheet

    private var actionSheet: UIAlertController?
    
    /**
     The identifier of the current event displayed at the bottom of the table (just above the toolbar).
     Use to anchor the message displayed at the bottom during table refresh.
     */
    private var currentEventIdAtTableBottom: String? {
        get {
            return self.value(forKey: "currentEventIdAtTableBottom") as? String
        }
        set {
            self.setValue(newValue, forKey: "currentEventIdAtTableBottom")
        }
    }
    
    /**
     Boolean value used to scroll to bottom the bubble history after refresh.
     */
    private var shouldScrollToBottomOnTableRefresh: Bool {
        get {
            let value = self.value(forKey: "shouldScrollToBottomOnTableRefresh") as? Bool
            return value ?? false
        }
        set {
            self.setValue(newValue, forKey: "shouldScrollToBottomOnTableRefresh")
        }
    }
    
    // The table view cell in which the read marker is displayed (nil by default).

    var readMarkerTableViewCell: MXKRoomBubbleTableViewCell?
    
    // Tell whether the view controller is appeared or not.
    var isAppeared = false
    
    // Observers

    // Observers to manage MXSession state (and sync errors)

    private var kMXSessionStateDidChangeObserver: Any?
    
    // Observers to manage ongoing conference call banner

    private var kMXCallStateDidChangeObserver: Any?
    private var kMXCallManagerConferenceStartedObserver: Any?
    private var kMXCallManagerConferenceFinishedObserver: Any?
    
    // Observers to manage widgets

    private var kMXKWidgetManagerDidUpdateWidgetObserver: Any?
    
    // Observe kAppDelegateNetworkStatusDidChangeNotification to handle network status change.

    private var kAppDelegateNetworkStatusDidChangeNotificationObserver: Any?
    
    // Observe kAppDelegateDidTapStatusBarNotification to handle tap on clock status bar.
    private var kAppDelegateDidTapStatusBarNotificationObserver: Any?
    
    // Observe UIMenuControllerDidHideMenuNotification to cancel text selection
    private var UIMenuControllerDidHideMenuNotificationObserver: Any?
    private var selectedText: String?
    
    // Typing notifications listener.

    private var typingNotifListener: Any?

    private let disposeBag = DisposeBag()
    
    private var updatOffset: Bool = true
}

extension CKRoomViewController {
    
    // MARK: - Override MXKRoomViewController
    
    public override class func nib() -> UINib? {
        return UINib.init(
            nibName: CKRoomViewController.nibName,
            bundle: Bundle(for: self))
    }
    
    override func destroy() {
        invitationController = nil
        for barButtonItem in navigationItem.rightBarButtonItems ?? [] {
            barButtonItem.isEnabled = false
        }

        if currentAlert != nil {
            currentAlert?.dismiss(animated: false)
            currentAlert = nil
        }

        if customizedRoomDataSource != nil {
            customizedRoomDataSource?.selectedEventId = nil;
            customizedRoomDataSource = nil;
        }

        if kAppDelegateDidTapStatusBarNotificationObserver != nil {
            NotificationCenter.default.removeObserver(kAppDelegateDidTapStatusBarNotificationObserver!)
            kAppDelegateDidTapStatusBarNotificationObserver = nil
        }

        if kAppDelegateNetworkStatusDidChangeNotificationObserver != nil {
            NotificationCenter.default.removeObserver(kAppDelegateNetworkStatusDidChangeNotificationObserver!)
            kAppDelegateNetworkStatusDidChangeNotificationObserver = nil
        }
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.mxEventDidChangeSentState, object: nil)
        NotificationCenter.default.removeObserver(self, name: .presentPhotoLibrary, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        self.removeTypingNotificationsListener()
        self.removeCallNotificationsListeners()
        self.removeWidgetNotificationsListeners()

        super.destroy()
    }
    
    override func finalizeInit() {
        super.finalizeInit()

        // Listen to the event sent state changes
        NotificationCenter.default.addObserver(self, selector: #selector(self.eventDidChangeSentState(_:)), name: NSNotification.Name.mxEventDidChangeSentState, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.receivePresentPhotoLibrary(_:)), name: .presentPhotoLibrary, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidBecomeActive(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupBubblesTableView()
        self.setupMentionTableView()
        
        // Custom attackmentViewController
        self.setAttachmentsViewerClass(CKAttachmentsViewController.self)
        // Replace the default input toolbar view.
        // Note: this operation will force the layout of subviews. That is why cell view classes must be registered before.
        updateRoomInputToolbarViewClassIfNeeded()
        
        // set extra area
        self.setRoomActivitiesViewClass(RoomActivitiesView.self)

        // Set up the room title view according to the data source (if any)
        self.refreshRoomNavigationBar()
        
        // Refresh tool bar if the room data source is set.
        if roomDataSource != nil {
            refreshRoomInputToolbar()
        }
        
        self.invitationController.delegate = self

        bindingTheme()
        
        // -- fix bug sync room members from server
        forceUpdateMemberInRoom()
        
        // -- init roomContextMenuPresent
        self.roomContextualMenuPresenter = RoomContextualMenuPresenter()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.view.setNeedsLayout() // force update layout
        navigationController?.view.layoutIfNeeded() // to fix height of the navigation bar
        self.refreshRoomNavigationBar()
        
        // listen notifications
        self.listenTypingNotifications()
        self.listenCallNotifications()
        self.listenWidgetNotifications()
        
        // Observe kAppDelegateDidTapStatusBarNotification.
        kAppDelegateDidTapStatusBarNotificationObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.appDelegateDidTapStatusBar, object: nil, queue: OperationQueue.main, using: { notif in

            self.bubblesTableView.setContentOffset(CGPoint(x: -self.bubblesTableView.mxk_adjustedContentInset.left, y: -self.bubblesTableView.mxk_adjustedContentInset.top), animated: true)

        })
         
//        self.roomDataSource?.reload() // fix bug CK 270, app has feature auto backup key
        
        if self.roomInputToolbarContainerBottomConstraint.constant == 0 {
            self.view.endEditing(true)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        isAppeared = true
        self.checkReadMarkerVisibility()
        
        if self.roomDataSource != nil {
            // Set visible room id
            AppDelegate.the().visibleRoomId = roomDataSource.roomId
        }
        
        // Observe network reachability
        kAppDelegateNetworkStatusDidChangeNotificationObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.appDelegateNetworkStatusDidChange, object: nil, queue: OperationQueue.main, using: { notif in
            self.refreshActivitiesViewDisplay()

        })
        refreshActivitiesViewDisplay()

        // Warn about the beta state of e2e encryption when entering the first time in an encrypted room
        let account: MXKAccount? = MXKAccountManager.shared().account(forUserId: roomDataSource?.mxSession?.myUser?.userId)
        if account != nil && account?.isWarnedAboutEncryption == nil && roomDataSource.room.summary.isEncrypted {
            account?.isWarnedAboutEncryption = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.refreshRoomNavigationBar()
        }
        
        // trust all devices
        DispatchQueue.main.async {
            self.trustAllMember()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // hide action
        if currentAlert != nil {
            currentAlert?.dismiss(animated: false)
            currentAlert = nil
        }
        
        // Cancel potential selected event (to leave edition mode)
        if customizedRoomDataSource?.selectedEventId != nil
        {
            self.cancelEventSelection()
        }
        
        if kAppDelegateDidTapStatusBarNotificationObserver != nil {
            NotificationCenter.default.removeObserver(kAppDelegateDidTapStatusBarNotificationObserver!)
            kAppDelegateDidTapStatusBarNotificationObserver = nil
        }
        
        // remove notifications
        self.removeTypingNotificationsListener()
        self.removeCallNotificationsListeners()
        self.removeWidgetNotificationsListeners()
        
        // Re-enable the read marker display, and disable its update.
        roomDataSource?.showReadMarker = true
        updateRoomReadMarker = false
        isAppeared = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Reset visible room id
        AppDelegate.the().visibleRoomId = nil

        if kAppDelegateNetworkStatusDidChangeNotificationObserver != nil {
            NotificationCenter.default.removeObserver(kAppDelegateNetworkStatusDidChangeNotificationObserver!)
            kAppDelegateNetworkStatusDidChangeNotificationObserver = nil
        }
    }

    private func bindingTheme() {
        // Binding navigation bar color
        themeService.attrsStream.subscribe(onNext: { [weak self] (theme) in
            self?.defaultBarTintColor = themeService.attrs.primaryBgColor
            self?.barTitleColor = themeService.attrs.primaryTextColor
            self?.bubblesTableView?.reloadData()
            self?.refreshRoomInputToolbar()

            self?.view.backgroundColor = themeService.attrs.primaryBgColor
            self?.bubblesTableView?.backgroundColor = themeService.attrs.primaryBgColor
            self?.mentionListTableView?.backgroundColor = themeService.attrs.primaryBgColor

            // Fix: has a white subview of view
            self?.view.subviews.first?.backgroundColor = themeService.attrs.primaryBgColor
        }).disposed(by: disposeBag)

        // Don't subscrible theme change
        self.navigationController?.view.backgroundColor = themeService.attrs.primaryBgColor
    }
    
    private func setupBubblesTableView() {
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
        
        // style
        bubblesTableView.keyboardDismissMode = .interactive
    }
    
    private func setupMentionTableView() {
        // register cell
        mentionListTableView.register(CKMentionUserTableViewCell.nib(), forCellReuseIdentifier: CKMentionUserTableViewCell.defaultReuseIdentifier())

        // add border
        let border = CALayer()
        border.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 1.0)
        border.backgroundColor = CKColor.Misc.borderColor.cgColor
        mentionListTableView.layer.addSublayer(border)
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
        var failedEventIds = [String]()

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
    
    func cancelAllUnsentMessages() {
        // Remove unsent event ids
        
        let outgoingMsgs = roomDataSource?.room?.outgoingMessages() ?? []
        
        for event in outgoingMsgs {
            if event.sentState == MXEventSentStateFailed {
                roomDataSource.removeEvent(withEventId: event.eventId)
            }
        }
    }

    func listenToServerNotices() {
        if serverNotices == nil {
            serverNotices = MXServerNotices(matrixSession: roomDataSource.mxSession)
            serverNotices?.delegate = self
        }
    }

    func isRoomPreview() -> Bool {
        // Check first whether some preview data are defined.
        if let _ = roomPreviewData {
            return true
        }

        if let data = roomDataSource, data.state == MXKDataSourceStateReady, let rooms = data.room,
            let sum = rooms.summary, sum.membership == MXMembership.invite {
            return true
        }

        return false
    }

    func updateMentionTableView(mentionDataSource: CKMentionDataSource?) {
        self.mentionListTableView?.dataSource = mentionDataSource
        self.mentionListTableView?.delegate = mentionDataSource
        
        if mentionDataSource != nil {
            self.mentionListTableView.isHidden = false
            self.mentionListTableView?.reloadData()
            
            let inputToolbarViewHeight: CGFloat = self.inputToolbarHeight()
            var visibleAreaHeight = view.frame.size.height - keyboardHeight - inputToolbarViewHeight
            
            // Hardcode to fix layout bug
            visibleAreaHeight -= 100
            
            if self.mentionListTableView.contentSize.height > visibleAreaHeight {
                self.mentionListTableViewHeightConstraint.constant = visibleAreaHeight
            } else {
                self.mentionListTableViewHeightConstraint.constant = self.mentionListTableView.contentSize.height
            }
            self.mentionListTableView.layoutIfNeeded()
        } else {
            self.mentionListTableView.isHidden = true
        }
    }
    
    @objc func navigationSearchBarButtonPressed(_ sender: UIBarButtonItem) {
        // If the beforeLastVC is RoomSearchViewController, will need to pop
        let stackViewControllers = navigationController?.viewControllers ?? []
        if stackViewControllers.count > 1 {
            let beforeLastVC = stackViewControllers[stackViewControllers.count - 2]
            if beforeLastVC.isKind(of: RoomSearchViewController.self) {
                self.navigationController?.popViewController(animated: true)
                return
            }
        }

        // show RoomSearchViewController
        self.vc_removeBackTitle()
        performSegue(withIdentifier: kShowRoomSearchSegue, sender: self)
    }
    
    @objc func navigationVoiceCallBarButtonPressed(_ sender: UIBarButtonItem) {
        if !isCallingInRoom() {
            self.checkMediaPermission(video: false, completion: { [weak self] (granted) in
                if granted {
                    self?.performCalling(video: false)
                }
            })
        }
    }

    @objc func navigationVideoCallBarButtonPressed(_ sender: UIBarButtonItem) {
        if !isCallingInRoom() {
            self.checkMediaPermission(video: true, completion: { [weak self] (granted) in
                if granted {
                    self?.performCalling(video: true)
                }
            })
        }
    }
    
    @objc func navigationHangupCallBarButtonPressed(_ sender: UIBarButtonItem) {
        if isCallingInRoom() {
            self.hangupCall()
        }
    }

    @objc func navigationStartChatBarButtonPressed(_ sender: UIBarButtonItem) {
        self.goBackToLive()
    }

    override func startActivityIndicator() {
        // TODO: don't use start activity indicator
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.invitationController?.update()
    }
    
    // MARK: Prepare for segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if segue.identifier == kShowRoomSearchSegue {
            // Dismiss keyboard
            dismissKeyboard()

            let roomSearchViewController = segue.destination as? RoomSearchViewController
            // Add the current data source to be able to search messages.
            roomSearchViewController?.roomDataSource = roomDataSource
        }
    }
    
    // MARK: Input Tool Bar
    
    // Set the input toolbar according to the current display
    func updateRoomInputToolbarViewClassIfNeeded() {
        var roomInputToolbarViewClass: AnyClass? = CKRoomInputToolbarView.self

        // Check the user has enough power to post message
        if roomDataSource?.roomState != nil {
            let powerLevels: MXRoomPowerLevels? = roomDataSource.roomState.powerLevels
            let userPowerLevel: Int? = powerLevels?.powerLevelOfUser(withUserID: roomDataSource.mxSession?.myUser?.userId)

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
            height = (inputToolbarView as? CKRoomInputToolbarView)?.mainToolbarHeightConstraint.constant ?? 0.0
        } else if (inputToolbarView is DisabledRoomInputToolbarView) {
            height = (inputToolbarView as? DisabledRoomInputToolbarView)?.mainToolbarMinHeightConstraint.constant ?? 0.0
        }

        return height
    }
    
    func refreshRoomInputToolbar() {
        if inputToolbarView != nil && (inputToolbarView is CKRoomInputToolbarView) {
            let roomInputToolbarView = inputToolbarView as! CKRoomInputToolbarView
            roomInputToolbarView.backgroundColor = themeService.attrs.primaryBgColor
            roomInputToolbarView.growingTextView?.placeholderColor = themeService.attrs.placeholderTextColor
            roomInputToolbarView.growingTextView?.textColor = themeService.attrs.primaryTextColor
            roomInputToolbarView.growingTextView?.tintColor = themeService.attrs.placeholderTextFieldColor
        } else if inputToolbarView != nil && (inputToolbarView is DisabledRoomInputToolbarView) {
            let roomInputToolbarView = inputToolbarView as! DisabledRoomInputToolbarView

            roomInputToolbarView.backgroundColor = themeService.attrs.secondBgColor
            roomInputToolbarView.disabledReasonTextView.textColor = themeService.attrs.primaryTextColor

            // For the moment, there is only one reason to use `DisabledRoomInputToolbarView`
            roomInputToolbarView.setDisabledReason(NSLocalizedString("room_do_not_have_permission_to_post", tableName: "Vector", bundle: Bundle.main, value: "", comment: ""))
        }
    }
    
    override func setRoomActivitiesViewClass(_ roomActivitiesViewClass: AnyClass!) {
        // Do not show room activities in case of preview (FIXME: show it when live events will be supported during peeking)
        if isRoomPreview() {
            super.setRoomActivitiesViewClass(nil)
        } else {
            super.setRoomActivitiesViewClass(roomActivitiesViewClass)
        }
    }

    func sendTextMessage(_ msgTxt: String?, isEdit: Bool = false) {
        if isInReplyMode, let selectedEventId = customizedRoomDataSource?.selectedEventId {
            roomDataSource?.sendReplyToEvent(withId: selectedEventId, withTextMessage: msgTxt, success: nil, failure: { error in
                // Just log the error. The message will be displayed in red in the room history
                print("[MXKRoomViewController] replyTextMessage failed.")
            })
        } else {
            if isEdit, let selectedEventId = customizedRoomDataSource?.selectedEventId, self.isValidEditMessage(text: msgTxt ?? "") {
                roomDataSource?.replaceTextMessageForEvent(withId: selectedEventId, withTextMessage: msgTxt, success:nil, failure: { error in
                    // Just log the error. The message will be displayed in red in the room history
                    print("[MXKRoomViewController] editTextMessage failed.")
                })
            } else {
                // Let the datasource send it and manage the local echo
                roomDataSource.sendTextMessage(msgTxt, success: { (response) in
                    
                }) { error in
                    // Just log the error. The message will be displayed in red in the room history
                    print("[MXKRoomViewController] sendTextMessage failed: \(error?.localizedDescription ?? "Undefined")")
                }
            }
        }

        cancelEventSelection()
    }
    
    func refreshRoomNavigationBar(_ isRefreshRoomTitle: Bool = true) {
        
        // Set the right room title view
        if self.isRoomPreview() {
            // Do not show the right buttons
            navigationItem.rightBarButtonItems = nil
            
            if isRefreshRoomTitle && self.roomDataSource != nil {
                self.setRoomTitleViewClass(RoomTitleView.self)
            }
            
            if self.roomDataSource == nil && self.roomPreviewData != nil {
                (self.titleView as? RoomTitleView)?.displayNameTextField.text = self.roomPreviewData?.roomName
                (self.titleView as? RoomTitleView)?.topicLabel.text = self.roomPreviewData?.roomTopic
            }
            
        } else {
            // searchBarButton
            let searchButton : UIButton = UIButton.init(type: .custom)
            searchButton.setImage(#imageLiteral(resourceName: "ic_search").withRenderingMode(.alwaysOriginal), for: .normal)
            searchButton.addTarget(self, action: #selector(navigationSearchBarButtonPressed(_:)), for: .touchUpInside)
            searchButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            let searchBarButton = UIBarButtonItem(customView: searchButton)

            // voiceCallBarButton
            let voiceCallButton : UIButton = UIButton.init(type: .custom)
            voiceCallButton.setImage(#imageLiteral(resourceName: "ic_voice_call_new").withRenderingMode(.alwaysOriginal), for: .normal)
            voiceCallButton.addTarget(self, action: #selector(navigationVoiceCallBarButtonPressed(_:)), for: .touchUpInside)
            voiceCallButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            let voiceCallBarButton = UIBarButtonItem(customView: voiceCallButton)

            // videoCallBarButton
            let videoCallButton : UIButton = UIButton.init(type: .custom)
            videoCallButton.setImage(#imageLiteral(resourceName: "ic_video_call_new").withRenderingMode(.alwaysOriginal), for: .normal)
            videoCallButton.addTarget(self, action: #selector(navigationVideoCallBarButtonPressed(_:)), for: .touchUpInside)
            videoCallButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            let videoCallBarButton = UIBarButtonItem(customView: videoCallButton)

            // hangupCallBarButton
            let hangupCallButton : UIButton = UIButton.init(type: .custom)
            hangupCallButton.setImage(#imageLiteral(resourceName: "ic_call_hang_up").withRenderingMode(.alwaysOriginal), for: .normal)
            hangupCallButton.addTarget(self, action: #selector(navigationHangupCallBarButtonPressed(_:)), for: .touchUpInside)
            hangupCallButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            let hangupCallBarButton = UIBarButtonItem(customView: hangupCallButton)
            
            if isSupportCallOption() {
                if isCallingInRoom() {
                    (self.titleView as? RoomTitleView)?.numberBarButtonItem = 2;
                    navigationItem.rightBarButtonItems = [searchBarButton, hangupCallBarButton]
                } else {
                    (self.titleView as? RoomTitleView)?.numberBarButtonItem = 3;
                    navigationItem.rightBarButtonItems = [searchBarButton, voiceCallBarButton, videoCallBarButton]
                }
            } else {
                navigationItem.rightBarButtonItems = [searchBarButton]
            }
            
            // Validate rightBarButtonItems
            if self.roomDataSource != nil {
                
                if self.roomDataSource.isLive {
                    // Enable the right buttons (Search and Call)
                    for barButtonItem in navigationItem.rightBarButtonItems ?? [] {
                        barButtonItem.isEnabled = true
                    }
                    
                    if isRefreshRoomTitle {
                        self.setRoomTitleViewClass(RoomTitleView.self)
                        (self.titleView as? RoomTitleView)?.tapGestureDelegate = self
                        (self.titleView as? RoomTitleView)?.displayNameTextField.theme.textColor = themeService.attrStream{ $0.primaryTextColor }
                    }
                } else {
                    let startChatButton = UIBarButtonItem.init(title: "Chat", style: .plain, target: self, action: #selector(navigationStartChatBarButtonPressed(_:)))
                    navigationItem.rightBarButtonItems = [startChatButton]
                    
                    if isRefreshRoomTitle {
                        self.setRoomTitleViewClass(SimpleRoomTitleView.self)
                        titleView?.editable = false
                        (self.titleView as? SimpleRoomTitleView)?.displayNameTextField.theme.textColor = themeService.attrStream{ $0.primaryTextColor }
                    }
                }
            } else {
                // Disbale the right buttons (Search and Call)
                for barButtonItem in navigationItem.rightBarButtonItems ?? [] {
                    barButtonItem.isEnabled = false
                }
                
                if isRefreshRoomTitle {
                    self.setRoomTitleViewClass(RoomTitleView.self)
                    (self.titleView as? RoomTitleView)?.tapGestureDelegate = self
                    (self.titleView as? RoomTitleView)?.displayNameTextField.theme.textColor = themeService.attrStream{ $0.primaryTextColor }
                }
            }
        }
        
        // -- Show status room chat follow status of user
        if let `titleView` = self.titleView as? RoomTitleView, let statusImage = titleView.roomDetailsIconImageView {
             
            var online: Bool = false
            
            let myUser = (AppDelegate.the()?.mxSessions.first as? MXSession)?.myUser
            
            for member in self.customizedRoomDataSource?.roomState.members.members ?? [] {
                
                // -- ignore case member == myUser
                if member.originUserId == myUser?.userId {
                    continue
                }
                
                switch member.membership.identifier {
                case __MXMembershipUnknown, __MXMembershipInvite, __MXMembershipLeave, __MXMembershipBan:
                    continue
                default:
                    print(member.originUserId)
                }
                
                online = self.checkOnline(member.originUserId)
            }
            
            if online {
                statusImage.shadowLayer(fillColor: #colorLiteral(red: 0.5764705882, green: 0.9647058824, blue: 0.6156862745, alpha: 1))
            } else {
                statusImage.shadowLayer(fillColor: #colorLiteral(red: 0.4392156863, green: 0.4392156863, blue: 0.4392156863, alpha: 1))
            }
            
            titleView.topicLabel.theme.textColor = themeService.attrStream{ $0.primaryTextColor }
        }
    }
    
    private func checkOnline(_ userId: String) -> Bool {
        
        guard let session = AppDelegate.the()?.mxSessions.first as? MXSession, let user = session.user(withUserId: userId) else {
            return false
        }
        
        switch user.presence {
        case MXPresenceOnline:
            return true
        default:
            return false
        }
    }
    
    
    func enableReplyMode(_ enable: Bool) {
        isInReplyMode = enable

        if inputToolbarView != nil && inputToolbarView?.isKind(of: RoomInputToolbarView.self) == true {
            (inputToolbarView as? RoomInputToolbarView)?.isReplyToEnabled = enable
        }
    }
    
    @objc func onSwipeGesture(_ swipeGestureRecognizer: UISwipeGestureRecognizer?) {
        let view: UIView? = swipeGestureRecognizer?.view

        if view == activitiesView {
            // Dismiss the keyboard when user swipes down on activities view.
            inputToolbarView.dismissKeyboard()
        }
    }
    
    // MARK: Setup Call feature
    
    func isCallingInRoom() -> Bool {
        if self.roomDataSource != nil {
            let callInRoom = self.roomDataSource?.mxSession?.callManager?.call(inRoom: self.roomDataSource.roomId)
            if (callInRoom != nil && callInRoom?.state != MXCallState.ended) || (AppDelegate.the().jitsiViewController?.widget?.roomId == roomDataSource.roomId) {
                // there is an active call in this room
                return true
            }
        }
        return false
    }
    
    func isSupportCallOption() -> Bool {
        // Check whether the call option is supported
        var isSupportCallOption = self.roomDataSource?.mxSession?.callManager != nil && (self.roomDataSource?.room?.summary?.membersCount?.joined ?? 0) >= 2
        
        let callInRoom = self.roomDataSource?.mxSession?.callManager?.call(inRoom: self.roomDataSource.roomId)
        if (callInRoom != nil && callInRoom?.state != MXCallState.ended) || (AppDelegate.the().jitsiViewController?.widget?.roomId == roomDataSource?.roomId) {
            // there is an active call in this room
        } else {
            // Hide the call button if there is an active call in another room
            isSupportCallOption = isSupportCallOption && (AppDelegate.the()?.callStatusBarWindow == nil)
        }
        
        return isSupportCallOption
    }
    
    func checkMediaPermission(video: Bool, completion: ((Bool) -> Void)?) {
        let appDisplayName = (Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String) ?? ""
        
        // Check app permissions first
        
        let messageForAudio = String(format: Bundle.mxk_localizedString(forKey: "microphone_access_not_granted_for_call"), appDisplayName)
        let messageForVideo = String(format: Bundle.mxk_localizedString(forKey: "camera_access_not_granted_for_call"), appDisplayName)
        
        MXKTools.checkAccess(forCall: video, manualChangeMessageForAudio: messageForAudio, manualChangeMessageForVideo: messageForVideo, showPopUpIn: self) { (granted) in
            if granted {
                completion?(granted)
            } else {
                print("RoomViewController: Warning: The application does not have the perssion to place the call")
                completion?(false)
            }
        }
    }
    
    func handleCallToRoom(_ sender: UIBarButtonItem?) {
        
        // Ask the user the kind of the call: voice or video?
        actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        actionSheet!.addAction(UIAlertAction(title: NSLocalizedString("voice", tableName: "Vector", bundle: Bundle.main, value: "", comment: ""), style: .default, handler: { [weak self] action in
            self?.actionSheet = nil
            self?.checkMediaPermission(video: false,completion: { (granted) in
                if granted {
                    self?.performCalling(video: false)
                }
            })
        }))

        actionSheet!.addAction(UIAlertAction(title: NSLocalizedString("video", tableName: "Vector", bundle: Bundle.main, value: "", comment: ""), style: .default, handler: { [weak self] action in
            self?.actionSheet = nil
            self?.checkMediaPermission(video: true, completion: { (granted) in
                if granted {
                    self?.performCalling(video: true)
                }
            })
        }))
        
        actionSheet!.addAction(UIAlertAction(title: NSLocalizedString("cancel", tableName: "Vector", bundle: Bundle.main, value: "", comment: ""), style: .cancel, handler: { [weak self] action in
            self?.actionSheet = nil
        }))

        if let view = sender?.customView {
            actionSheet?.popoverPresentationController?.sourceView = view
            actionSheet?.popoverPresentationController?.sourceRect = view.bounds
        }
        
        self.present(actionSheet!, animated: true, completion: nil)
    }
    
    func performCalling(video: Bool) {
        
        // If there is already a jitsi widget, join it
        if let jitsiWidget = customizedRoomDataSource?.jitsiWidget()
        {
            AppDelegate.the().displayJitsiViewController(with: jitsiWidget, andVideo: video)
            self.refreshRoomNavigationBar()
        }
        // If enabled, create the conf using jitsi widget and open it directly
        else if RiotSettings.shared.createConferenceCallsWithJitsi && (self.roomDataSource?.room?.summary?.membersCount?.joined ?? 0) > 2
        {
            self.startActivityIndicator()
            
            WidgetManager.shared()?.createJitsiWidget(in: self.roomDataSource.room, withVideo: video, success: { [weak self] (jitsiWidget) in
                self?.stopActivityIndicator()
                AppDelegate.the().displayJitsiViewController(with: jitsiWidget, andVideo: video)
                self?.refreshRoomNavigationBar()
            }, failure: { [weak self] (error) in
                self?.stopActivityIndicator()
                if let error = error {
                    self?.showJitsiError(error)
                }
                self?.refreshRoomNavigationBar()
            })
            
        }
        // Classic conference call is not supported in encrypted rooms
        else if self.roomDataSource?.room?.summary?.isEncrypted == true && (self.roomDataSource?.room?.summary?.membersCount?.joined ?? 0) > 2
        {
            currentAlert?.dismiss(animated: false, completion: nil)
            
            currentAlert = UIAlertController(title: Bundle.mxk_localizedString(forKey: "room_no_conference_call_in_encrypted_rooms"), message: nil, preferredStyle: .alert)
            
            currentAlert?.addAction(UIAlertAction(title: Bundle.mxk_localizedString(forKey: "ok"), style: .default, handler: { [weak self] _ in
                self?.currentAlert = nil
            }))

            currentAlert!.mxk_setAccessibilityIdentifier("RoomVCCallAlert")
            present(currentAlert!, animated: true)
        }
        // In case of conference call, check that the user has enough power level
        else if (roomDataSource?.room?.summary?.membersCount?.joined ?? 0) > 2 && !MXCallManager.canPlaceConferenceCall(in: roomDataSource.room, roomState: roomDataSource.roomState)
        {
            currentAlert?.dismiss(animated: false, completion: nil)
            
            currentAlert = UIAlertController(title: Bundle.mxk_localizedString(forKey: "room_no_power_to_create_conference_call"), message: nil, preferredStyle: .alert)
            
            currentAlert?.addAction(UIAlertAction(title: Bundle.mxk_localizedString(forKey: "ok"), style: .default, handler: { [weak self] _ in
                self?.currentAlert = nil
            }))
            
            currentAlert!.mxk_setAccessibilityIdentifier("RoomVCCallAlert")
            present(currentAlert!, animated: true)
        }
        // Classic 1:1 or group call can be done
        else
        {
            self.roomDataSource?.room?.placeCall(withVideo: video) { call in
                call.value?.answer()
                self.refreshRoomNavigationBar()
            }
        }
    }
    
    func hangupCall() {
        if let roomId = roomDataSource?.roomId, let callInRoom = roomDataSource?.mxSession?.callManager?.call(inRoom: roomId) {
            callInRoom.hangup()
        } else if (AppDelegate.the().jitsiViewController?.widget?.roomId == roomDataSource?.roomId) {
            AppDelegate.the().jitsiViewController?.hangup()
        }

        refreshActivitiesViewDisplay()
        
        // refresh call button
        refreshRoomNavigationBar()
    }
    
    private func trustAllMember() {
        
        // an of array user id which need to be trusted
        var userIds = [String]()
        
        // put all room's member ids to the array, except my user id
        for user in self.roomDataSource?.roomState?.members?.members ?? [] {
            
            // pick not my id
            if let myid = self.mainSession?.myUser?.userId, myid != user.userId {
                userIds.append(user.userId)
            }
        }
        
        // download user's key
        self.mainSession?.crypto?.downloadKeys(userIds, forceDownload: true, success: { (usersDevicesInfoMap) in
            
            // set known user's device
            self.mainSession?.crypto?.setDevicesKnown(usersDevicesInfoMap, complete: nil)
            
            // verifying all devices
            for userId in userIds {
                
                // an array of device ids
                if let deviceIds = usersDevicesInfoMap?.deviceIds(forUser: userId) {
                    
                    for deviceId in deviceIds {
                        
                        // verifying a device
                        self.mainSession?.crypto?.setDeviceVerification(
                            
                            // succeed to verify
                            MXDeviceVerified, forDevice: deviceId, ofUser: userId, success: {
                        }, failure: { (_) in
                            
                            // failed to verify
                            print("[CK] Fail to verified deviceId: \(deviceId) for userId: \(userId)")
                        })
                    }
                }
            }
        }, failure: nil)
    }
    
    // MARK: - Widget notifications management
    
    func removeWidgetNotificationsListeners() {
        if kMXKWidgetManagerDidUpdateWidgetObserver != nil {
            NotificationCenter.default.removeObserver(kMXKWidgetManagerDidUpdateWidgetObserver!)
            kMXKWidgetManagerDidUpdateWidgetObserver = nil
        }
    }

    func listenWidgetNotifications() {
        kMXKWidgetManagerDidUpdateWidgetObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.widgetManagerDidUpdateWidget, object: nil, queue: OperationQueue.main, using: { notif in

            let widget = notif.object as? Widget
            if widget?.mxSession == self.roomDataSource?.mxSession && (widget?.roomId == self.customizedRoomDataSource?.roomId) {
                // Jitsi conference widget existence is shown in the bottom bar
                // Update the bar
                self.refreshActivitiesViewDisplay()
                self.refreshRoomInputToolbar()
                self.refreshRoomNavigationBar()
            }
        })
    }
    
    func showJitsiError(_ error: Error) {
        // Customise the error for permission issues
        var nsError = error as NSError
        if nsError.domain == WidgetManagerErrorDomain && nsError.code == WidgetManagerErrorCodeNotEnoughPower.rawValue {
            nsError = NSError.init(domain: nsError.domain, code: nsError.code, userInfo: [
                NSLocalizedDescriptionKey: NSLocalizedString("room_conference_call_no_power", tableName: "Vector", bundle: Bundle.main, value: "", comment: "")
                ])
        }
        
        // Alert user
        AppDelegate.the().showError(asAlert: nsError)
    }
    
    func widgetsCount(_ includeUserWidgets: Bool) -> Int {
        var widgetsCount = WidgetManager.shared().widgetsNot(ofTypes: [kWidgetTypeJitsi], in: roomDataSource.room, with: roomDataSource.roomState).count
        if includeUserWidgets {
            widgetsCount += WidgetManager.shared().userWidgets(roomDataSource.room.mxSession).count
        }
        
        return widgetsCount
    }
    
    // MARK: - Typing management

    func removeTypingNotificationsListener() {
        if let roomDataSource = self.roomDataSource {
            // Remove the previous live listener
            if typingNotifListener != nil {
                roomDataSource.room?.liveTimeline({ [weak self] liveTimeline in
                    if let strongSelf = self {
                        liveTimeline?.removeListener(strongSelf.typingNotifListener)
                        strongSelf.typingNotifListener = nil
                    }
                })
            }
        }

        self.currentTypingUsers = nil
    }
    
    func listenTypingNotifications() {
        if let roomDataSource = self.roomDataSource {
            // Add typing notification listener
            typingNotifListener = roomDataSource.room?.listen(toEventsOfTypes: [NSNotification.Name.mxEventTypeStringTyping.rawValue], onEvent: { [weak self] (event, direction, roomState) in
                if let strongSelf = self {
                    // Handle only live events
                    if direction == __MXTimelineDirectionForwards {
                        // Retrieve typing users list
                        var typingUsers = strongSelf.roomDataSource?.room?.typingUsers ?? []
                        
                        // Remove typing info for the current user
                        if let index = typingUsers.firstIndex(where: { $0 == strongSelf.mainSession?.myUser?.userId }) {
                            typingUsers.remove(at: index)
                        }
                        
                        // Ignore this notification if both arrays are empty
                        if (strongSelf.currentTypingUsers?.count ?? 0) > 0 || typingUsers.count > 0 {
                            strongSelf.currentTypingUsers = typingUsers
                            strongSelf.refreshActivitiesViewDisplay()
                        }
                    }
                }
            })

            // Retrieve the current typing users list
            var typingUsers = self.roomDataSource?.room?.typingUsers ?? []
            // Remove typing info for the current user
            if let index = typingUsers.firstIndex(where: { $0 == self.mainSession?.myUser?.userId }) {
                typingUsers.remove(at: index)
            }
            currentTypingUsers = typingUsers
            refreshActivitiesViewDisplay()
        }
    }
    
    func refreshTypingNotification() -> Bool {
        if self.activitiesView.isKind(of: RoomActivitiesView.self) {
            // Prepare here typing notification
            var text: String? = nil
            let count = self.currentTypingUsers?.count ?? 0

            // get the room member names
            var names: [String] = []

            // keeps the only the first two users
            for i in 0..<min(count, 2) {
                var name = currentTypingUsers?[i]

                let member: MXRoomMember? = roomDataSource?.roomState?.members?.member(withUserId: name)

                if member != nil && (member?.displayname?.count ?? 0) > 0 {
                    name = member?.displayname
                }

                // sanity check
                if let name = name {
                    names.append(name)
                }
            }

            if 0 == names.count {
                // something to do ?
            } else if 1 == names.count {
                text = String(format: NSLocalizedString("room_one_user_is_typing", tableName: "Vector", bundle: Bundle.main, value: "", comment: ""), names[0])
            } else if 2 == names.count {
                if count > 2 {
                    text = String(format: NSLocalizedString("room_many_users_are_typing", tableName: "Vector", bundle: Bundle.main, value: "", comment: ""), names[0], names[1])
                } else {
                    text = String(format: NSLocalizedString("room_two_users_are_typing", tableName: "Vector", bundle: Bundle.main, value: "", comment: ""), names[0], names[1])
                }
            } else {
                text = String(format: NSLocalizedString("room_many_users_are_typing", tableName: "Vector", bundle: Bundle.main, value: "", comment: ""), names[0], names[1])
            }
            if activitiesView.isHidden {
                self.updatOffset = (text ?? "").count != 0
            }
            (activitiesView as? RoomActivitiesView)?.displayTypingNotification(text)
            return (text ?? "").count != 0
        }
        return false
    }
    
    // MARK: Unreachable Network Handling
    
    func refreshActivitiesViewDisplay() {
        // TODO: implement
        
        self.roomActivitiesContainer?.isHidden = false
        
        if self.activitiesView == nil {
            return
        }
        
        var shallRVshowing = false
        
        var unreadCount: UInt = 0
        
        if self.activitiesView.isKind(of: RoomActivitiesView.self) {
            
            let roomActivitiesView = self.activitiesView as! RoomActivitiesView
            
            // Reset gesture recognizers
            while (roomActivitiesView.gestureRecognizers?.count ?? 0) > 0 {
                if let gestureRecognizers = roomActivitiesView.gestureRecognizers?.first {
                    roomActivitiesView.removeGestureRecognizer(gestureRecognizers)
                }
            }

            let jitsiWidget = customizedRoomDataSource?.jitsiWidget()

            if (roomDataSource?.mxSession?.syncError?.errcode == kMXErrCodeStringResourceLimitExceeded) {
                shallRVshowing = true
                roomActivitiesView.showResourceLimitExceededError(roomDataSource?.mxSession?.syncError?.userInfo, onAdminContactTapped: { adminContact in
                    if let adminContact = adminContact {
                        if UIApplication.shared.canOpenURL(adminContact) {
                            UIApplication.shared.open(adminContact, options: [:], completionHandler: nil)
                        } else {
                            print("[RoomVC] refreshActivitiesViewDisplay: adminContact(\(adminContact)) cannot be opened")
                        }
                    }
                })
            }
            else if AppDelegate.the()?.isOffline == true {
                shallRVshowing = true
                roomActivitiesView.displayNetworkErrorNotification(NSLocalizedString("room_offline_notification", tableName: "Vector", bundle: Bundle.main, value: "", comment: ""))
            } else if customizedRoomDataSource?.roomState?.isObsolete == true {
                if let replacementRoomId = customizedRoomDataSource?.roomState.tombStoneContent.replacementRoomId {
                    let roomLinkFragment = "/room/\((replacementRoomId as NSString).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "")"
                    
                    roomActivitiesView.displayRoomReplacement(roomLinkTappedHandler: {
                        AppDelegate.the().handleUniversalLinkFragment(roomLinkFragment)
                    })
                }
            }
            else if customizedRoomDataSource?.roomState?.isOngoingConferenceCall == true {
                // Show the "Ongoing conference call" banner only if the user is not in the conference
                let callInRoom: MXCall? = roomDataSource?.mxSession?.callManager?.call(inRoom: roomDataSource.roomId)
                if callInRoom != nil, let state = callInRoom?.state, state != MXCallState.ended {
                    if checkUnsentMessages() == false {
                        shallRVshowing = refreshTypingNotification()
                    }
                } else {
                    shallRVshowing = true
                    roomActivitiesView.displayOngoingConferenceCall({ video in

                        print("[RoomVC] onOngoingConferenceCallPressed")

                        // Make sure there is not yet a call
                        if self.customizedRoomDataSource?.mxSession?.callManager?.call(inRoom: self.customizedRoomDataSource?.roomId ?? "") == nil {
                            self.customizedRoomDataSource?.room?.placeCall(withVideo: video, completion: { (_) in
                                
                            })
                        }
                    }, onClosePressed: nil)
                }
            }
            else if let jitsiWidget = jitsiWidget {
                // The room has an active jitsi widget
                // Show it in the banner if the user is not already in
                if AppDelegate.the().jitsiViewController?.widget?.widgetId == jitsiWidget.widgetId {
                    if checkUnsentMessages() == false {
                        shallRVshowing = refreshTypingNotification()
                    }
                } else {
                    shallRVshowing = true
                    roomActivitiesView.displayOngoingConferenceCall({ (video) in
                        print("[RoomVC] onOngoingConferenceCallPressed (jitsi)")

                        let appDisplayName = (Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String) ?? ""

                        // Check app permissions first

                        let messageForAudio = String(format: Bundle.mxk_localizedString(forKey: "microphone_access_not_granted_for_call"), appDisplayName)
                        let messageForVideo = String(format: Bundle.mxk_localizedString(forKey: "camera_access_not_granted_for_call"), appDisplayName)

                        MXKTools.checkAccess(forCall: video, manualChangeMessageForAudio: messageForAudio, manualChangeMessageForVideo: messageForVideo, showPopUpIn: self) { (granted) in
                            if granted {
                                // Present the Jitsi view controller
                                AppDelegate.the()?.displayJitsiViewController(with: jitsiWidget, andVideo: video)
                            } else {
                                print("[RoomVC] onOngoingConferenceCallPressed: Warning: The application does not have the perssion to join the call")
                            }
                        }
                    }) { [weak self] in

                        if let strongSelf = self {
                            strongSelf.startActivityIndicator()
                            
                            WidgetManager.shared().closeWidget(jitsiWidget.widgetId, in: strongSelf.roomDataSource.room, success: {
                                strongSelf.stopActivityIndicator()
                                
                                // The banner will automatically leave thanks to kWidgetManagerDidUpdateWidgetNotification
                            }, failure: { error in
                                if let error = error {
                                    strongSelf.showJitsiError(error)
                                }
                                strongSelf.stopActivityIndicator()
                            })

                        }
                    }
                }
            }
            else if !self.checkUnsentMessages() {
                // Show "scroll to bottom" icon when the most recent message is not visible,
                // or when the timelime is not live (this icon is used to go back to live).
                // Note: we check if `currentEventIdAtTableBottom` is set to know whether the table has been rendered at least once.
                if roomDataSource?.isLive != true || (currentEventIdAtTableBottom != nil && isBubblesTableScrollViewAtTheBottom() == false) {

                    // Retrieve the unread messages count
//                    let unreadCount = roomDataSource?.room?.summary?.localUnreadEventCount ?? 0
                    unreadCount = roomDataSource?.room?.summary?.localUnreadEventCount ?? 0

                    if unreadCount == 0 {
                        // Refresh the typing notification here
                        // We will keep visible this notification (if any) beside the "scroll to bottom" icon.
                        
                        shallRVshowing = refreshTypingNotification()
                    }

                    shallRVshowing = (unreadCount != 0)
                    roomActivitiesView.displayScroll(toBottomIcon: unreadCount, onIconTapGesture: {
                        self.goBackToLive()
                    })
                }
                else if let usageLimit = serverNotices?.usageLimit, usageLimit.isServerNoticeUsageLimit {
                    shallRVshowing = true
                    roomActivitiesView.showResourceUsageLimitNotice(usageLimit, onAdminContactTapped: { adminContact in

                        if let adminContact = adminContact {
                            if UIApplication.shared.canOpenURL(adminContact) {
                                UIApplication.shared.open(adminContact, options: [:], completionHandler: nil)
                            } else {
                                print("[RoomVC] refreshActivitiesViewDisplay: adminContact(\(adminContact)) cannot be opened")
                            }
                        }
                    })
                }
                else
                {
                    shallRVshowing = refreshTypingNotification()
                }
            }
            
            // Recognize swipe downward to dismiss keyboard if any
            let swipe = UISwipeGestureRecognizer(target: self, action: #selector(self.onSwipeGesture(_:)))
            swipe.numberOfTouchesRequired = 1
            swipe.direction = .down
            roomActivitiesView.addGestureRecognizer(swipe)
            
                        
            if shallRVshowing {
                roomActivitiesView.isHidden = false
                self.roomActivitiesContainerHeightConstraint.constant = roomActivitiesView.height
                
                // check unread message and bool update layout finish ---> adjust content offset show last message
                if unreadCount == 0 && self.updatOffset {
                    if (roomContextualMenuPresenter?.isPresenting ?? false) {
                        return
                    }
                    self.bubblesTableView.scrollToBottom(roomActivitiesView.height)
                    self.updatOffset = false
                }
                
            } else {
                self.updatOffset = true
                roomActivitiesView.isHidden = true
                self.roomActivitiesContainerHeightConstraint.constant = 0
            }
        }
    }
    
    func goBackToLive() {
        if roomDataSource?.isLive == true {
            // Enable the read marker display, and disable its update (in order to not mark as read all the new messages by default).
            roomDataSource.showReadMarker = true
            updateRoomReadMarker = false

            scrollBubblesTableViewToBottom(animated: true)
        } else {
            // Switch back to the room live timeline managed by MXKRoomDataSourceManager
            let roomDataSourceManager = MXKRoomDataSourceManager.sharedManager(forMatrixSession: mainSession)

            roomDataSourceManager?.roomDataSource(forRoom: roomDataSource.roomId, create: true, onComplete: { [weak self] roomDataSource in

                // Scroll to bottom the bubble history on the display refresh.
                self?.shouldScrollToBottomOnTableRefresh = true

                self?.displayRoom(roomDataSource)

                // The room view controller do not have here the data source ownership.
                self?.hasRoomDataSourceOwnership = false

                self?.refreshActivitiesViewDisplay()

                if self?.saveProgressTextInput == true {
                    // Restore the potential message partially typed before jump to last unread messages.
                    self?.inputToolbarView.textMessage = roomDataSource?.partialTextMessage
                }

                // Sync room members from server to fix bug:
                // The membersCount is differrent between before and after load from MXKRoomDataSourceManager
                roomDataSource?.room.members({ (members) in
                    if let newJoinedCount = members?.joinedMembers.count {
                        roomDataSource?.room.summary.membersCount.joined = UInt(newJoinedCount)
                        roomDataSource?.delegate.dataSource(roomDataSource, didCellChange: nil)
                    }
                }, lazyLoadedMembers: { (_) in
                    //
                }, failure: { (error) in
                    print("Sync room members failed")
                })
            })
        }
    }

    // MARK: - Preview
    
    @objc func displayRoomPreview(_ previewData: RoomPreviewData?) {
        // Release existing room data source or preview
        displayRoom(nil)

        if previewData != nil {
            self.isEventsAcknowledgementEnabled = false

            addMatrixSession(previewData!.mxSession)

            roomPreviewData = previewData

            refreshRoomNavigationBar()

            if let roomDataSource = roomPreviewData?.roomDataSource {
                super.displayRoom(roomDataSource)
            }
        }
    }
    
    // MARK: - Override MXKRoomViewController
    override func onMatrixSessionChange() {
        super.onMatrixSessionChange()

        // Re-enable the read marker display, and disable its update.
        roomDataSource?.showReadMarker = true
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
        if let _ = roomPreviewData {
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
            
            // Store ref on customized room data source
            if dataSource?.isKind(of: CKRoomDataSource.self) == true {
                customizedRoomDataSource = dataSource as? CKRoomDataSource
            }
        }
        else
        {
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        }
        
        self.refreshRoomNavigationBar()
        self.refreshRoomInputToolbar()
    }
    
    override func updateAppearanceOnRoomDataSourceState() {
        super.updateAppearanceOnRoomDataSourceState()
        
        if self.isRoomPreview() {
            self.navigationItem.rightBarButtonItem?.isEnabled = false

            // Remove input tool bar if any
            if self.inputToolbarView != nil {
                super.setRoomInputToolbarViewClass(nil)
            }
            
            // invitation view
            self.titleView?.editable = false
            self.titleView?.refreshDisplay()
            self.invitationController?.showIt(true, roomDataSource: self.roomDataSource, previewData: self.roomPreviewData)
        } else {
            // invitation view
            self.invitationController?.showIt(false, roomDataSource: self.roomDataSource, previewData: self.roomPreviewData)
            
            navigationItem.rightBarButtonItem?.isEnabled = roomDataSource != nil
            titleView?.editable = false
            
            if self.roomDataSource != nil {
                
                // Restore tool bar view and room activities view if none
                if self.inputToolbarView == nil {
                    self.updateRoomInputToolbarViewClassIfNeeded()
                    self.refreshRoomInputToolbar()
                    
                    self.inputToolbarView?.isHidden = self.roomDataSource?.state != MXKDataSourceStateReady
                }

                if self.activitiesView == nil {
                    // And the extra area
                    self.setRoomActivitiesViewClass(RoomActivitiesView.self)
                }
            }
            
            self.refreshRoomNavigationBar(false)
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
        
        var memberName = (roomMember.displayname ?? "").count > 0 ? roomMember.displayname : roomMember.userId
        
        // If the first character is mentionTriggerCharacter then need to remove it
        if memberName?.first == CKRoomInputToolbarView.mentionTriggerCharacter {
            memberName?.removeFirst()
        }
        
        var taggingText = ""
        
        if (roomMember.userId == mainSession.myUser?.userId) {
            taggingText = String.init(CKRoomInputToolbarView.mentionTriggerCharacter) + "me "
        } else {
            taggingText = "\(String.init(CKRoomInputToolbarView.mentionTriggerCharacter))\(memberName ?? "") "
        }

        if let inputToolbarView = inputToolbarView as? CKRoomInputToolbarView,
            let growingTextView = inputToolbarView.growingTextView {
            
            let selectedRange = growingTextView.selectedRange
            var firstHalfString = (growingTextView.text as NSString?)?.substring(to: selectedRange.location)
            let lastHalfString = (growingTextView.text as NSString?)?.substring(from: selectedRange.location)

            if firstHalfString?.contains(String.init(CKRoomInputToolbarView.mentionTriggerCharacter)) == true {
                let mentionComponents = firstHalfString?.components(separatedBy: String.init(CKRoomInputToolbarView.mentionTriggerCharacter))
                let currentMentionComponent = mentionComponents?.last

                if let currentMentionComponent = currentMentionComponent,
                    !currentMentionComponent.contains(" ") {  // case: "@xyz..."
                    for _ in 0..<(firstHalfString?.count ?? 0) {
                        let removedChar = firstHalfString?.removeLast()
                        
                        if removedChar == CKRoomInputToolbarView.mentionTriggerCharacter {
                            break
                        }
                    }
                    
                    firstHalfString = (firstHalfString ?? "") + taggingText
                    growingTextView.text = (firstHalfString ?? "") + (lastHalfString ?? "")
                    
                    if let newSelectedLocation = firstHalfString?.count {
                        growingTextView.selectedRange = NSRange.init(location: newSelectedLocation, length: 0)
                    }
                } else { // case: just only "@"
                    inputToolbarView.pasteText(taggingText)
                }
            } else { // programmatically mention
                inputToolbarView.pasteText(taggingText)
            }
        }
    }
    
    override func dataSource(_ dataSource: MXKDataSource!, shouldDoAction actionIdentifier: String!, inCell cell: MXKCellRendering!, userInfo: [AnyHashable : Any]! = [:], defaultValue: Bool) -> Bool {

        // if long press then typeClick == 1
        let typeClick = userInfo?[kMXKRoomBubbleCellUrlItemInteraction] as? Int
        
        // other press gestures
        if typeClick != 1 {
            let urlClicked = userInfo?[kMXKRoomBubbleCellUrl] as? URL

            if let urlString = urlClicked?.absoluteString.removingPercentEncoding, actionIdentifier.contains(kMXKRoomBubbleCellShouldInteractWithURL),
                MXTools.isMatrixRoomAlias(urlString) || MXTools.isMatrixRoomIdentifier(urlString) {
                
                // Open the room or preview it
                let fragmentPath = "/room/\(MXTools.encodeURIComponent(urlString) ?? "")"
                AppDelegate.the()?.handleUniversalLinkFragment(fragmentPath)

                return false
            }

            AppUtils.openURL(url: urlClicked)
        }

        return true
    }
    
    override func dataSource(_ dataSource: MXKDataSource?, didRecognizeAction actionIdentifier: String?, inCell cell: MXKCellRendering?, userInfo: [AnyHashable : Any]?) {
        
        isPresentPhotoLibrary = false
        
        // Handle here user actions on bubbles for Vector app
        var bubbleData: RoomBubbleCellData!
        
        if customizedRoomDataSource != nil, let roomBubbleTableViewCell = cell as? MXKRoomBubbleTableViewCell {
            bubbleData = roomBubbleTableViewCell.bubbleData as? RoomBubbleCellData
        }
        
        // is long press event?
        if actionIdentifier == kMXKRoomBubbleCellLongPressOnEvent && cell?.isKind(of: MXKRoomBubbleTableViewCell.self) == true {
//            self.resignFirstResponder()
            guard let cell = cell, let roomBubbleTableViewCell = cell as? MXKRoomBubbleTableViewCell else {
                    return
            }
            let attachment = roomBubbleTableViewCell.bubbleData.attachment

            // Create new AlertViewController
            currentAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

            // Add actions for text message
            // Handle this case to add "Quote" action.
            if attachment == nil {
                guard let selectedEvent = userInfo?[kMXKRoomBubbleCellEventKey] as? MXEvent else {
                    return
                }
                
                let components = roomBubbleTableViewCell.bubbleData.bubbleComponents ?? [MXKRoomBubbleComponent]()
                let selectedComponent: MXKRoomBubbleComponent? = components.first(where: {$0.event.eventId == selectedEvent.eventId})
                
                if currentAlert != nil {
//                    currentAlert?.dismiss(animated: false, completion: nil)
                    
                    
                    // Cancel potential text selection in other bubbles
                    for cell in self.bubblesTableView.visibleCells {
                        if let bubbleCell = cell as? MXKRoomBubbleTableViewCell {
                            bubbleCell.highlightTextMessage(forEvent: nil)
                        }
                    }
                }

                // Add actions for a failed event
                if selectedEvent.sentState == MXEventSentStateFailed {
                    currentAlert?.addAction(UIAlertAction(title: NSLocalizedString("room_event_action_resend", tableName: "Vector", bundle: Bundle.main, value: "", comment: ""), style: .default, handler: { [weak self] _ in
                        guard let weakSelf = self else {
                            return
                        }
                        
                        weakSelf.cancelEventSelection()
                        weakSelf.roomDataSource.resendEvent(withEventId: selectedEvent.eventId,
                                                            success: nil,
                                                            failure: nil)
                    }))
                    
                    currentAlert?.addAction(UIAlertAction(title: NSLocalizedString("room_event_action_delete", tableName: "Vector", bundle: Bundle.main, value: "", comment: ""), style: .default, handler: { [weak self] _ in
                        guard let weakSelf = self else {
                            return
                        }
                        
                        weakSelf.cancelEventSelection()
                        weakSelf.roomDataSource.removeEvent(withEventId: selectedEvent.eventId)
                    }))
                }
                
                // Add actions for text message
                // Check status of the selected event
                if selectedEvent.sentState == MXEventSentStatePreparing ||
                    selectedEvent.sentState == MXEventSentStateEncrypting ||
                    selectedEvent.sentState == MXEventSentStateSending {
                    currentAlert?.addAction(UIAlertAction(title: NSLocalizedString("room_event_action_cancel_send", tableName: "Vector", bundle: Bundle.main, value: "", comment: ""), style: .default, handler: { [weak self] _ in
                        guard let weakSelf = self else {
                            return
                        }
                        
                        weakSelf.currentAlert = nil
                        
                        // Cancel and remove the outgoing message
                        weakSelf.roomDataSource.room.cancelSendingOperation(selectedEvent.eventId)
                        weakSelf.roomDataSource.removeEvent(withEventId: selectedEvent.eventId)
                        
                        weakSelf.cancelEventSelection()
                    }))
                }
                
                currentAlert?.addAction(UIAlertAction(title: NSLocalizedString("room_event_action_copy", tableName: "Vector", bundle: Bundle.main, value: "", comment: ""), style: .default, handler: { [weak self] _ in
                    guard let weakSelf = self, let selectedComponent = selectedComponent else {
                        return
                    }

                    weakSelf.cancelEventSelection()
                    
                    UIPasteboard.general.string = selectedComponent.textMessage
                }))
                
                if self.roomDataSource.canEditEvent(withId: selectedEvent.eventId) {
                    currentAlert?.addAction(UIAlertAction(title: NSLocalizedString("room_event_action_edit", tableName: "Vector", bundle: Bundle.main, value: "", comment: ""), style: .default, handler: { [weak self] _ in
                        guard let weakSelf = self, let _ = selectedComponent else {
                            return
                        }
                        weakSelf.cancelEventSelection()
                        weakSelf.editEvent(with: selectedEvent.eventId)
                    }))
                    
                    currentAlert?.addAction(UIAlertAction(title: NSLocalizedString("remove", tableName: "Vector", bundle: Bundle.main, value: "", comment: ""), style: .default, handler: { [weak self] _ in
                        guard let weakSelf = self else {
                            return
                        }
                        weakSelf.cancelEventSelection()
                        weakSelf.removeEvent(with: selectedEvent.eventId)
                        
                    }))
                }
                
                // Add action for room message only
                if selectedEvent.eventType == __MXEventTypeRoomMessage {
                    currentAlert?.addAction(UIAlertAction(title: NSLocalizedString("room_event_action_quote", tableName: "Vector", bundle: Bundle.main, value: "", comment: ""), style: .default, handler: { [weak self] _ in
                        guard let weakSelf = self else {
                            return
                        }
                        
                        weakSelf.cancelEventSelection()
                        weakSelf.inputToolbarView.textMessage = String(format: "%@\n>%@\n\n",
                                                                       self?.inputToolbarView.textMessage ?? "",
                                                                       selectedComponent?.textMessage ?? "")
                        
                        weakSelf.inputToolbarView.becomeFirstResponder()
                    }))
                }
                
                currentAlert?.addAction(UIAlertAction(title: NSLocalizedString("room_event_action_share", tableName: "Vector", bundle: Bundle.main, value: "", comment: ""), style: .default, handler: { [weak self] _ in
                    guard let weakSelf = self else {
                        return
                    }
                    
                    weakSelf.cancelEventSelection()
                    
                    let activityViewController = UIActivityViewController(activityItems: [selectedComponent?.textMessage ?? ""], applicationActivities: nil)
                    
                    activityViewController.modalTransitionStyle = .coverVertical
                    activityViewController.popoverPresentationController?.sourceView = roomBubbleTableViewCell
                    activityViewController.popoverPresentationController?.sourceRect = roomBubbleTableViewCell.bounds
                    
                    weakSelf.present(activityViewController, animated: true, completion: nil)
                }))
                
                if components.count > 1 {
                    currentAlert?.addAction(UIAlertAction(title: "Select All", style: .default, handler: { [weak self] _ in
                        guard let weakSelf = self else {
                            return
                        }
                        
                        weakSelf.currentAlert = nil
                        weakSelf.selectAllTextMessage(inCell: roomBubbleTableViewCell)
                    }))
                }
                
                if selectedEvent.sentState == MXEventSentStateSent {
                    // Check whether download is in progress
                    if selectedEvent.isMediaAttachment() {
                        let downloadId = roomBubbleTableViewCell.bubbleData.attachment.downloadId
                        if let loader = MXMediaManager.existingDownloader(withIdentifier: downloadId) {
                            currentAlert?.addAction(UIAlertAction(title: NSLocalizedString("room_event_action_cancel_download", tableName: "Vector", bundle: Bundle.main, value: "", comment: ""), style: .default, handler: { [weak self] _ in
                                guard let weakSelf = self else {
                                    return
                                }
                                
                                weakSelf.cancelEventSelection()
                                loader.cancel()
                                roomBubbleTableViewCell.progressView.isHidden = true
                            }))
                        }
                    }
                    
                    currentAlert?.addAction(UIAlertAction(title: "Show Details", style: .default, handler: { [weak self] _ in
                        guard let weakSelf = self else {
                            return
                        }
                        weakSelf.currentAlert = nil
                        
                        // Cancel event highlighting (if any)
                        roomBubbleTableViewCell.highlightTextMessage(forEvent: nil)
                        
                        // Display event details
                        weakSelf.showEventDetails(selectedEvent)
                    }))
                }
                self.showActionAlert(sourceView: roomBubbleTableViewCell)
            } else if let fileName = attachment?.originalFileName {
                attachment?.getData({ (data) in
                    self.currentAlert?.addAction(UIAlertAction(title: NSLocalizedString("room_event_action_share", tableName: "Vector", bundle: Bundle.main, value: "", comment: ""), style: .default, handler: { [weak self] _ in
                        guard let weakSelf = self else {
                            return
                        }
                        weakSelf.cancelEventSelection()
                        let tempDirectoryURL = URL.init(fileURLWithPath: NSTemporaryDirectory().appending(fileName))
                        do {
                            try data?.write(to: tempDirectoryURL)

                            // Force unwrap since we checked "attachment == nil" of the first 'if' statement
                            let activityViewController = UIActivityViewController(activityItems: [tempDirectoryURL], applicationActivities: nil)
                            activityViewController.modalTransitionStyle = .coverVertical
                            activityViewController.popoverPresentationController?.sourceView = roomBubbleTableViewCell
                            activityViewController.popoverPresentationController?.sourceRect = roomBubbleTableViewCell.bounds
                            weakSelf.present(activityViewController, animated: true, completion: nil)
                        } catch let err {
                            print(err.localizedDescription)
                        }
                    }))

                }, failure: { (error) in
                    print(error.debugDescription)
                })
                
                if let selectedEvent = userInfo?[kMXKRoomBubbleCellEventKey] as? MXEvent {
                    currentAlert?.addAction(UIAlertAction(title: "Show Details", style: .default, handler: { [weak self] _ in
                        guard let weakSelf = self else {
                            return
                        }
                        weakSelf.cancelEventSelection()

                        // Cancel event highlighting (if any)
                        roomBubbleTableViewCell.highlightTextMessage(forEvent: nil)
                        
                        // Display event details
                        weakSelf.showEventDetails(selectedEvent)
                    }))
                    
                    
                    if self.roomDataSource.canEditEvent(withId: selectedEvent.eventId) {
                        currentAlert?.addAction(UIAlertAction(title: NSLocalizedString("remove", tableName: "Vector", bundle: Bundle.main, value: "", comment: ""), style: .default, handler: { [weak self] _ in
                            guard let weakSelf = self else {
                                return
                            }
                            weakSelf.cancelEventSelection()
                            weakSelf.removeEvent(with: selectedEvent.eventId)
                        }))
                    }
                }
                
                self.showActionAlert(sourceView: roomBubbleTableViewCell)
            }
            
        } else if actionIdentifier == kMXKRoomBubbleCellTapOnAvatarView {
            dismissKeyboard()

            // click user avatar in room go to  view info profile
            let idAvatarTap = userInfo?[kMXKRoomBubbleCellUserIdKey] as? String
            
            // is current ser
            if idAvatarTap == mainSession.myUser.userId {
                
                // shows account profile
                self.showPersonalAccountProfile()
            } else {
                
                // get member, show its profile
                if let mxMember = roomDataSource?.roomState?.members.member(withUserId: idAvatarTap) {
                    self.showOthersAccountProfile(mxMember: mxMember)
                }
            }
        } else if actionIdentifier == kMXKRoomBubbleCellTapOnSenderNameLabel {
            dismissKeyboard()
            // Do nothing
        } else if (actionIdentifier == kMXKRoomBubbleCellTapOnMessageTextView) || (actionIdentifier == kMXKRoomBubbleCellTapOnContentView) {

            // Retrieve the tapped event
            guard let `userInfo` = userInfo, let tappedEvent: MXEvent = userInfo[kMXKRoomBubbleCellEventKey] as? MXEvent else { return }

            // Check whether a selection already exist or not
            if customizedRoomDataSource?.selectedEventId != nil {
                self.cancelEventSelection()
                return
            }

            if tappedEvent.eventType == __MXEventTypeRoomCreate {
                // Handle tap on RoomPredecessorBubbleCell
                let createContent: MXRoomCreateContent = MXRoomCreateContent(fromJSON: tappedEvent.content)
                let predecessorRoomId = createContent.roomPredecessorInfo?.roomId
                if (predecessorRoomId != nil) {
                    // Show predecessor room
                    AppDelegate.the()?.showRoom(predecessorRoomId, andEventId: nil, withMatrixSession: self.mainSession)
                }
            } else {
                // Show contextual menu on single tap if bubble is not collapsed
                if bubbleData.collapsed {
                    self.selectEvent(withId: tappedEvent.eventId)
                } else {
                    self.showContextualMenu(for: tappedEvent, fromSingleTapGesture: true, cell: cell, animated: true)
                }
            }
        } else { // call super
            super.dataSource(dataSource, didRecognizeAction: actionIdentifier, inCell: cell, userInfo: userInfo)
        }
    }
    
    private func showActionAlert(sourceView: MXKRoomBubbleTableViewCell) {
        currentAlert?.addAction(UIAlertAction(title: NSLocalizedString("cancel", tableName: "Vector", bundle: Bundle.main, value: "", comment: ""), style: .default, handler: { [weak self] _ in
            guard let weakSelf = self else {
                return
            }
            weakSelf.cancelEventSelection()
        }))
        
        currentAlert?.mxk_setAccessibilityIdentifier("RoomVCEventMenuAlert")
        currentAlert?.popoverPresentationController?.sourceView = sourceView
        currentAlert?.popoverPresentationController?.sourceRect = sourceView.bounds
        if let currentAlert = self.currentAlert {
            self.present(currentAlert, animated: true) {
                let tap = UITapGestureRecognizer.init(target: self, action: #selector(self.dismissCurrentAlert(_:)))
                currentAlert.view.superview?.subviews.first?.isUserInteractionEnabled = true
                currentAlert.view.superview?.subviews.first?.addGestureRecognizer(tap)
            }
        }
    }
    
    override func dataSource(_ dataSource: MXKDataSource!, didCellChange changes: Any!) {
        // data source update to super
        super.dataSource(dataSource, didCellChange: changes)

        // invisible
        if self.isViewVisible() == false {
            return
        }
        
        
        // refresh if did receive new message,...
        self.refreshActivitiesViewDisplay()
        self.refreshRoomNavigationBar()
        
        self.updatOffset = true //-- update state 
    }
    
    @objc private func dismissCurrentAlert(_ gesture: UITapGestureRecognizer) {
        
        guard currentAlert != nil else {
            self.cancelEventSelection()
            return
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    private func showRoomSettings() {
        if self.roomDataSource != nil {
            let nvc = CKRoomSettingsViewController.instanceNavigation { (vc: MXKTableViewController) in
                if let vc = vc as? CKRoomSettingsViewController {
                    vc.delegate = self
                    vc.initWith(self.roomDataSource.mxSession, andRoomId: self.roomDataSource.roomId)
                }
            }

            // present nvc
//            nvc.modalPresentationStyle = .fullScreen
            self.present(nvc, animated: true, completion: nil)
        }
    }
    
    func selectEvent(withId eventId: String?) {
        let shouldEnableReplyMode = roomDataSource.canReplyToEvent(withId: eventId)
        enableReplyMode(shouldEnableReplyMode)
        customizedRoomDataSource?.selectedEventId = eventId
        
        dataSource(roomDataSource, didCellChange: nil)
    }
    
    func cancelEventSelection() {
        enableReplyMode(false)

        if currentAlert != nil {
            currentAlert?.dismiss(animated: false)
            currentAlert = nil
        }

        customizedRoomDataSource?.selectedEventId = nil
        restoreTextBeforeEditing()

        // Force table refresh
        dataSource(roomDataSource, didCellChange: nil)
    }
    
    private func editEvent(with eventId: String?) {
        guard let event = roomDataSource.event(withEventId: eventId),
            let toolbarView = inputToolbarView as? CKRoomInputToolbarView else {
            return
        }
        
        textMessageBeforeEditing = toolbarView.textMessage
        customizedRoomDataSource?.selectedEventId = eventId
        toolbarView.textMessage = roomDataSource.editableTextMessage(for: event)
        toolbarView.setSendMode(mode: .edit)
        toolbarView.becomeFirstResponder()
    }
    
    private func removeEvent(with eventId : String?){
        guard let eventId = eventId else {return}
        roomDataSource.room.redactEvent(eventId, reason: nil) { _ in}
    }
    
    private func restoreTextBeforeEditing() {
        guard let toolbarView = inputToolbarView as? CKRoomInputToolbarView,
            let originalText = textMessageBeforeEditing else {
                return
        }
        
        toolbarView.textMessage = originalText
        textMessageBeforeEditing = nil
    }

    private func isValidEditMessage(text: String) -> Bool {
        guard let toolbarView = inputToolbarView as? CKRoomInputToolbarView else {
                return false
        }
        if text.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 {
            toolbarView.textMessage = ""
            toolbarView.setSendMode(mode: .send)

            return true
        } else {
            toolbarView.textMessage = ""
            toolbarView.setSendMode(mode: .send)

            return false
        }
    }
    
    // MARK: - Unsent Messages Handling

    func checkUnsentMessages() -> Bool {
        var hasUnsent = false
        var hasUnsentDueToUnknownDevices = false
     
        if self.activitiesView?.isKind(of: RoomActivitiesView.self) == true {
            let outgoingMsgs = roomDataSource?.room?.outgoingMessages() ?? []
            
            for event in outgoingMsgs {
                if event.sentState == MXEventSentStateFailed {
                    hasUnsent = true

                    // Check if the error is due to unknown devices
                    if (event.sentError?._domain == MXEncryptingErrorDomain) && event.sentError?._code == Int(Float(MXEncryptingErrorUnknownDeviceCode.rawValue)) {
                        hasUnsentDueToUnknownDevices = true
                        break
                    }
                }
            }

            if hasUnsent {
                let notification = hasUnsentDueToUnknownDevices ? NSLocalizedString("room_unsent_messages_unknown_devices_notification", tableName: "Vector", bundle: Bundle.main, value: "", comment: "") : NSLocalizedString("room_unsent_messages_notification", tableName: "Vector", bundle: Bundle.main, value: "", comment: "")
                let roomActivitiesView = activitiesView as! RoomActivitiesView
                
                roomActivitiesView.displayUnsentMessagesNotification(notification, withResendLink: {
                    self.resendAllUnsentMessages()
                }, andCancelLink: {
                    self.cancelAllUnsentMessages()
                }) { [weak self] in
                    
                    self?.currentAlert?.dismiss(animated: false, completion: nil)
                    
                    self?.currentAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

                    self?.currentAlert?.addAction(UIAlertAction(title: NSLocalizedString("room_resend_unsent_messages", tableName: "Vector", bundle: Bundle.main, value: "", comment: ""), style: .default, handler: { action in
                        self?.resendAllUnsentMessages()
                        self?.currentAlert = nil
                    }))

                    self?.currentAlert?.addAction(UIAlertAction(title: NSLocalizedString("room_delete_unsent_messages", tableName: "Vector", bundle: Bundle.main, value: "", comment: ""), style: .default, handler: { action in
                        self?.cancelAllUnsentMessages()
                        self?.currentAlert = nil
                    }))

                    self?.currentAlert?.addAction(UIAlertAction(title: NSLocalizedString("cancel", tableName: "Vector", bundle: Bundle.main, value: "", comment: ""), style: .cancel, handler: { action in
                        self?.currentAlert = nil
                    }))

                    self?.currentAlert?.mxk_setAccessibilityIdentifier("RoomVCUnsentMessagesMenuAlert")
                    self?.currentAlert?.popoverPresentationController?.sourceView = roomActivitiesView
                    self?.currentAlert?.popoverPresentationController?.sourceRect = roomActivitiesView.bounds
                    
                    if let currentAlert = self?.currentAlert {
                        self?.present(currentAlert, animated: true)
                    }
                }
            }
        }
        
        return hasUnsent
    }
    
    // Click avatar Show info profile
    private func showPersonalAccountProfile() {
        let nvc = CKAccountProfileViewController.instanceNavigation { (vc: MXKViewController) in
            vc.importSession(self.mxSessions)
            (vc as? CKAccountProfileViewController)?.isForcedPresenting = true
            if let roomDataSource = self.roomDataSource, roomDataSource.roomState != nil, let _ = roomDataSource.room {
                (vc as? CKAccountProfileViewController)?.mxRoomPowerLevels = roomDataSource.roomState.powerLevels
            }
        }
        self.present(nvc, animated: true, completion: nil)
    }
    
    private func showOthersAccountProfile(mxMember: MXRoomMember) {
        let nvc = CKOtherProfileViewController.instanceNavigation { (vc: MXKViewController) in
            vc.importSession(self.mxSessions)
            (vc as? CKOtherProfileViewController)?.mxMember = mxMember
            (vc as? CKOtherProfileViewController)?.isForcedPresenting = true
            if let roomDataSource = self.roomDataSource, roomDataSource.roomState != nil, let room = roomDataSource.room {
                (vc as? CKOtherProfileViewController)?.mxRoom = room
                (vc as? CKOtherProfileViewController)?.mxRoomPowerLevels = roomDataSource.roomState.powerLevels
            }
        }
        self.present(nvc, animated: true, completion: nil)
    }
}

// MARK: - MXServerNoticesDelegate

extension CKRoomViewController: MXServerNoticesDelegate {
    func serverNoticesDidChangeState(_ serverNotices: MXServerNotices?) {
        refreshActivitiesViewDisplay()
    }
}

// MARK: - RoomInputToolbarViewDelegate

extension CKRoomViewController: CKRoomInputToolbarViewDelegate {
    func shareImageAndFileDidTouch() {
        self.cancelEventSelection()
        self.resignFirstResponder()
    }
    
    override func roomInputToolbarView(_ toolbarView: MXKRoomInputToolbarView!, present alertController: UIAlertController!) {
        super.roomInputToolbarView(toolbarView, present: alertController)
        isPresentPhotoLibrary = false
    }

    @discardableResult
    override func resignFirstResponder() -> Bool {
        isPresentPhotoLibrary = false
        return super.resignFirstResponder()
    }

    override var inputView: UIView? {
        return currentInputView
    }

    @objc func receivePresentPhotoLibrary(_ notification: Notification) {
        currentInputView = nil
        if let photoPicker = notification.object as? ImagePickerController {
            photoPicker.view.autoresizingMask = .flexibleHeight
            self.imagePickerController = photoPicker
            self.currentInputView = photoPicker.view
            self.isPresentPhotoLibrary = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.becomeFirstResponder()
            }
        } else {
            print("Don't cast ImagePickerController")
        }
    }

    func sendFileDidSelect() {
        self.resignFirstResponder()
        self.openDocumentWindow()
    }

    func closeEditButtonDidPress() {
        self.textMessageBeforeEditing = nil
    }

    func sendTextButtonDidPress(_ message: String, isEdit: Bool) {
        self.sendTextMessage(message, isEdit: isEdit)
    }

    func roomInputToolbarView(_ toolbarView: MXKRoomInputToolbarView?, triggerMention: Bool, mentionText: String?) {

        func highlightMentionButton(highlight: Bool) {
            if let roomInputToolbarView = inputToolbarView as? CKRoomInputToolbarView {
                roomInputToolbarView.mentionButton.theme.tintColor = themeService.attrStream{ highlight ? $0.primaryTextColor : $0.secondTextColor }
            }
        }

        if triggerMention {
            
            var roomMembers: [MXRoomMember] = self.roomDataSource?.roomState.members.members ?? []
            if let mentionText = mentionText,
                mentionText.count > 0 {
                roomMembers = self.roomDataSource?.roomState.members.members.filter({ $0.displayname?.lowercased().contains(mentionText.lowercased()) == true }) ?? []
            }
            
            if roomMembers.count > 0 {
                mentionDataSource = CKMentionDataSource.init(roomMembers, matrixSession: self.mainSession, delegate: self)
                highlightMentionButton(highlight: true)
                return
            }
        }
        
        if mentionDataSource != nil {
            mentionDataSource = nil
        }
        highlightMentionButton(highlight: false)
    }
    
    override func roomInputToolbarView(_ toolbarView: MXKRoomInputToolbarView?, isTyping typing: Bool) {
        super.roomInputToolbarView(toolbarView, isTyping: typing)

        // Cancel potential selected event (to leave edition mode)
        if typing, let selectedEventId = customizedRoomDataSource?.selectedEventId, !roomDataSource.canReplyToEvent(withId: selectedEventId) {
            cancelEventSelection()
        }
    }

    override func roomInputToolbarView(_ toolbarView: MXKRoomInputToolbarView?, heightDidChanged height: CGFloat, completion: @escaping (_ finished: Bool) -> Void) {
        if let placeholder = toolbarView?.placeholder, placeholder.count > 0, roomInputToolbarContainerHeightConstraint?.constant != height {
            // Hide temporarily the placeholder to prevent its distorsion during height animation
            if savedInputToolbarPlaceholder == nil{
                savedInputToolbarPlaceholder = toolbarView?.placeholder ?? ""
            }
            toolbarView?.placeholder = nil

            super.roomInputToolbarView(toolbarView, heightDidChanged: height) { finished in

                //if completion
                completion(finished)

                // Consider here the saved placeholder only if no new placeholder has been defined during the height animation.
                if toolbarView?.placeholder == nil {
                    // Restore the placeholder if any
                    toolbarView?.placeholder = self.savedInputToolbarPlaceholder
                }
                self.savedInputToolbarPlaceholder = nil
            }
        } else {
            super.roomInputToolbarView(toolbarView, heightDidChanged: height) { finished in
                completion(finished)
            }
        }
    }
}

// MARK: - CKMentionDataSourceDelegate

extension CKRoomViewController: CKMentionDataSourceDelegate {
    func mentionDataSource(_ dataSource: CKMentionDataSource, didSelect member: MXRoomMember) {
        self.mention(member)
        mentionDataSource = nil
    }
}

// MARK: - RoomTitleViewTapGestureDelegate

extension CKRoomViewController: RoomTitleViewTapGestureDelegate {
    func roomTitleView(_ titleView: RoomTitleView?, recognizeTapGesture tapGestureRecognizer: UITapGestureRecognizer?) {
        self.showRoomSettings()
    }
}

// MARK: - MXSession state change

extension CKRoomViewController {
    func listenMXSessionStateChangeNotifications() {
        kMXSessionStateDidChangeObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.mxSessionStateDidChange, object: roomDataSource.mxSession, queue: OperationQueue.main, using: { notif in

            if self.roomDataSource.mxSession.state == MXSessionStateSyncError || self.roomDataSource.mxSession.state == MXSessionStateRunning {
                self.refreshActivitiesViewDisplay()

                // update inputToolbarView
                self.updateRoomInputToolbarViewClassIfNeeded()
                
                self.refreshRoomNavigationBar()
            }
        })
    }
    
    func removeMXSessionStateChangeNotificationsListener() {
        if kMXSessionStateDidChangeObserver != nil {
            NotificationCenter.default.removeObserver(kMXSessionStateDidChangeObserver!)
            kMXSessionStateDidChangeObserver = nil
        }
    }
}

// MARK: - Call notifications management

extension CKRoomViewController {
    func removeCallNotificationsListeners() {
        if kMXCallStateDidChangeObserver != nil {
            NotificationCenter.default.removeObserver(kMXCallStateDidChangeObserver!)
            kMXCallStateDidChangeObserver = nil
        }
        if kMXCallManagerConferenceStartedObserver != nil {
            NotificationCenter.default.removeObserver(kMXCallManagerConferenceStartedObserver!)
            kMXCallManagerConferenceStartedObserver = nil
        }
        if kMXCallManagerConferenceFinishedObserver != nil {
            NotificationCenter.default.removeObserver(kMXCallManagerConferenceFinishedObserver!)
            kMXCallManagerConferenceFinishedObserver = nil
        }
    }

    func listenCallNotifications() {
        kMXCallStateDidChangeObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: kMXCallStateDidChange), object: nil, queue: OperationQueue.main, using: { notif in

            let call = notif.object as? MXCall
            if (call?.room.roomId == self.customizedRoomDataSource?.roomId) {
                self.refreshActivitiesViewDisplay()
                self.refreshRoomInputToolbar()
            }
        })
        kMXCallManagerConferenceStartedObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: kMXCallManagerConferenceStarted), object: nil, queue: OperationQueue.main, using: { notif in

            let roomId = notif.object as? String
            if (roomId == self.customizedRoomDataSource?.roomId) {
                self.refreshActivitiesViewDisplay()
            }
        })
        kMXCallManagerConferenceFinishedObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: kMXCallManagerConferenceFinished), object: nil, queue: OperationQueue.main, using: { notif in

            let roomId = notif.object as? String
            if (roomId == self.customizedRoomDataSource?.roomId) {
                self.refreshActivitiesViewDisplay()
                self.refreshRoomInputToolbar()
            }
        })
    }
}

// MARK: - CKRoomSettingsViewControllerDelegate

extension CKRoomViewController: CKRoomSettingsViewControllerDelegate {
    func roomSettingsDidLeave() {
        AppDelegate.the()?.masterTabBarController.navigationController?.popViewController(animated: false)
    }
}

// MARK: - Override UIScrollViewDelegate

extension CKRoomViewController {
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
         checkReadMarkerVisibility()

        // Switch back to the live mode when the user scrolls to the bottom of the non live timeline.
        if let roomDataSource = roomDataSource, !roomDataSource.isLive, !isRoomPreview() {
            let contentBottomPosY: CGFloat = bubblesTableView.contentOffset.y + bubblesTableView.frame.size.height - bubblesTableView.mxk_adjustedContentInset.bottom

            if contentBottomPosY >= bubblesTableView.contentSize.height && !roomDataSource.timeline.canPaginate(MXTimelineDirection.forwards) {
                goBackToLive()
            }
        }
        
    }
    
    @objc override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if MXKRoomViewController.instancesRespond(to: #selector(self.scrollViewWillBeginDragging(_:))) {
            super.scrollViewWillBeginDragging(scrollView)
        }
    }

    @objc override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if MXKRoomViewController.instancesRespond(to: #selector(self.scrollViewDidEndDragging(_:willDecelerate:))) {
            super.scrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
        }

        if decelerate == false {

            refreshActivitiesViewDisplay()
        }
    }
    
    @objc override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if MXKRoomViewController.instancesRespond(to: #selector(self.scrollViewDidEndDecelerating(_:))) {
            super.scrollViewDidEndDecelerating(scrollView)
        }

        refreshActivitiesViewDisplay()
    }

    @objc override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if MXKRoomViewController.instancesRespond(to: #selector(self.scrollViewDidEndScrollingAnimation(_:))) {
            super.scrollViewDidEndScrollingAnimation(scrollView)
        }

        refreshActivitiesViewDisplay()
    }
}
 
// MARK: - Read marker handling

extension CKRoomViewController {
    func checkReadMarkerVisibility() {
        if let readMarkerTableViewCell = readMarkerTableViewCell, isAppeared, !isBubbleTableViewDisplayInTransition {
            // Check whether the read marker is visible
            let contentTopPosY: CGFloat = bubblesTableView.contentOffset.y + bubblesTableView.mxk_adjustedContentInset.top
            let readMarkerViewPosY: CGFloat = readMarkerTableViewCell.frame.origin.y + readMarkerTableViewCell.readMarkerView.frame.origin.y
            if contentTopPosY <= readMarkerViewPosY {
                // Compute the max vertical position visible according to contentOffset
                let contentBottomPosY: CGFloat = bubblesTableView.contentOffset.y + bubblesTableView.frame.size.height - bubblesTableView.mxk_adjustedContentInset.bottom
                if readMarkerViewPosY <= contentBottomPosY {
                    // Launch animation
                    animateReadMarkerView()

                    // Disable the read marker display when it has been rendered once.
                    roomDataSource.showReadMarker = false

                    // Update the read marker position according the events acknowledgement in this view controller.
                    updateRoomReadMarker = true

                    if roomDataSource.isLive {
                        // Move the read marker to the current read receipt position.
                        roomDataSource.room.forgetReadMarker()
                    }
                }
            }
        }
    }
        
    func animateReadMarkerView() {
        // Check whether the cell with the read marker is known and if the marker is not animated yet.
        if readMarkerTableViewCell != nil,
            readMarkerTableViewCell?.readMarkerView?.isHidden == true,
            let cellData = readMarkerTableViewCell?.bubbleData as? RoomBubbleCellData {

            // Do not display the marker if this is the last message.
            if cellData.containsLastMessage && readMarkerTableViewCell?.readMarkerView?.tag == cellData.mostRecentComponentIndex {
                readMarkerTableViewCell!.readMarkerView.isHidden = true
                readMarkerTableViewCell = nil
            } else {
                readMarkerTableViewCell!.readMarkerView.isHidden = false

                // Animate the layout to hide the read marker
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {

                    UIView.animate(withDuration: 1.5, delay: 0, options: [.beginFromCurrentState, .curveEaseIn], animations: {

                        // sure rmtc is live
                        if self.readMarkerTableViewCell == nil {
                            return
                        }
                        
                        self.readMarkerTableViewCell!.readMarkerViewTrailingConstraint.constant = self.readMarkerTableViewCell!.bubbleOverlayContainer.frame.size.width / 2
                        self.readMarkerTableViewCell!.readMarkerViewLeadingConstraint.constant = self.readMarkerTableViewCell!.readMarkerViewTrailingConstraint.constant
                        self.readMarkerTableViewCell!.readMarkerView.alpha = 0

                        // Force to render the view
                        self.readMarkerTableViewCell!.bubbleOverlayContainer.layoutIfNeeded()

                    }) { finished in

                        // sure rmtc is live
                        if self.readMarkerTableViewCell == nil {
                            return
                        }

                        self.readMarkerTableViewCell!.readMarkerView.isHidden = true
                        self.readMarkerTableViewCell!.readMarkerView.alpha = 1

                        self.readMarkerTableViewCell = nil
                    }
                })

            }
        }
    }
}

// MARK: - UITableViewDelegate

extension CKRoomViewController {
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if MXKRoomViewController.instancesRespond(to: #selector(self.tableView(_:willDisplay:forRowAt:))) {
            super.tableView(tableView, willDisplay: cell, forRowAt: indexPath)
        }
        
        cell.theme.backgroundColor = themeService.attrStream{ $0.primaryBgColor }

        // Update the selected background view
        if themeService.attrs.selectedBgColor != nil {
            cell.selectedBackgroundView = UIView()
            cell.selectedBackgroundView?.theme.backgroundColor = themeService.attrStream{ $0.selectedBgColor }
        } else {
            if tableView.style == .plain {
                cell.selectedBackgroundView = nil
            } else {
                cell.selectedBackgroundView?.backgroundColor = nil
            }
        }

        if cell.isKind(of: MXKRoomBubbleTableViewCell.self),
            let roomBubbleTableViewCell = cell as? MXKRoomBubbleTableViewCell {
            if roomBubbleTableViewCell.messageTextView != nil {
                roomBubbleTableViewCell.messageTextView.textColor = themeService.attrs.secondTextColor
                roomBubbleTableViewCell.userNameLabel?.textColor = themeService.attrs.primaryTextColor
                roomBubbleTableViewCell.statsLabel?.textColor = themeService.attrs.secondTextColor
                roomBubbleTableViewCell.messageTextView.delegate = self
                // we don't want to select text
                roomBubbleTableViewCell.messageTextView?.gestureRecognizers?.forEach({ (recognizer: UIGestureRecognizer) in
                    if let recognizer = recognizer as? UILongPressGestureRecognizer {
                        if let name = recognizer.name {
                            if name == "UITextInteractionNameLoupe" ||
                                name == "_UIKeyboardTextSelectionGestureForcePress" ||
                                name == "UITextInteractionNameTapAndHold" {
                                recognizer.isEnabled = false
                            }
                        }
                    }
                })
            }
            
            if roomBubbleTableViewCell.readMarkerView != nil {
                readMarkerTableViewCell = roomBubbleTableViewCell
                checkReadMarkerVisibility()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if cell == readMarkerTableViewCell {
            readMarkerTableViewCell = nil
        }

        if MXKRoomViewController.instancesRespond(to: #selector(self.tableView(_:didEndDisplaying:forRowAt:))) {
            super.tableView(tableView, didEndDisplaying: cell, forRowAt: indexPath)
        }
    }
}


extension CKRoomViewController: CKRoomInvitationControllerDeletate {
    
    func invitationDidSelectJoin() {
        
        // session
        var ms: MXSession! = self.mainSession
        
        // is nil?
        if ms == nil {
            
            // Get the first session of AppDelegate
            ms = AppDelegate.the()?.mxSessions.first as? MXSession
        }
        
//        guard let session = ms else {
//            self.showAlert("Occur an error. Please try to join chat later.")
//            return
//        }

        self.showSpinner(onView: UIApplication.topViewController()?.view ?? self.view)
        if let previewData = roomPreviewData {
            var roomIdOrAlias = previewData.roomId
            if let aliases = previewData.roomAliases, aliases.count > 0 {
                roomIdOrAlias = aliases.first
            }
            
            guard let roomID = roomIdOrAlias, roomID.count > 0 else {
                self.removeSpinner()
                return
            }

            var signURL: String?
            if let email = previewData.emailInvitation, let sign = email.signUrl {
                signURL = sign
            } else {
                signURL = nil
            }

            self.joinRoom(withRoomIdOrAlias: roomID, viaServers: previewData.viaServers, andSignUrl: signURL) {[weak self] (success) in
                self?.removeSpinner()
                if success {
                    // reload navbar
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self?.refreshRoomNavigationBar()
                    }
                } else {
                    // error: pre-handled in SDK
                }
            }
        } else {
            self.joinRoom {[weak self] (success) in
                self?.removeSpinner()
                if success {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self?.refreshRoomNavigationBar()
                    }
                }
            }
        }
    }
    
    func invitationDidSelectDecline() {
        
        if let invitedRoom = self.roomDataSource?.room {
            // alert obj
            let alert = UIAlertController(
                title: "Are you sure to decline this room?",
                message: nil,
                preferredStyle: .actionSheet)
            
            // leave room
            alert.addAction(UIAlertAction(title: "Decline", style: .default , handler:{ (_) in
                invitedRoom.leave(completion: { (response: MXResponse<Void>) in
                    if let error = response.error {
                        self.showAlert(error.localizedDescription)
                    } else {
                        AppDelegate.the()?.masterTabBarController?.navigationController?.popViewController(animated: true)
                    }
                })
            }))
            
            // cancel
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:{ (_) in
            }))
            
            // present
            self.present(alert, animated: true, completion: nil)
        } else {
            AppDelegate.the()?.masterTabBarController?.navigationController?.popViewController(animated: true)
        }
    }
}

// MARK: - UITextViewDelegate
extension CKRoomViewController : UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return false
    }
}

// MARK: - Clipboard
extension CKRoomViewController {
    
    /// Selected all text message in cell
    func selectAllTextMessage(inCell cell: MXKRoomBubbleTableViewCell) {
        
        guard let data = cell.bubbleData, let selectAllText = data.textMessage else {
            return
        }
        selectedText = selectAllText
        cell.allTextHighlighted = true
        DispatchQueue.main.async {
            self.UIMenuControllerDidHideMenuNotificationObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.UIMenuControllerDidHideMenu, object: nil, queue: OperationQueue.main, using: { (notifi) in
                cell.allTextHighlighted = false
                self.selectedText = nil
                UIMenuController.shared.menuItems = nil
                NotificationCenter.default.removeObserver(NSNotification.Name.UIMenuControllerDidHideMenu)
                self.UIMenuControllerDidHideMenuNotificationObserver = nil
            })
            
            self.inputToolbarView.becomeFirstResponder()
            
            let menu = UIMenuController.shared
            menu.menuItems = [UIMenuItem(title: "Share", action: #selector(self.share(_:)))]
            if #available(iOS 13.0, *) {
                menu.showMenu(from: cell.messageTextView, rect: cell.messageTextView.frame)
            } else {
                menu.setMenuVisible(true, animated: true)
            }
        }
    }
    
    @objc override func copy(_ sender: Any?) {
        UIPasteboard.general.string = selectedText
    }
    
    @objc func share(_ sender: Any?) {
        if let selectedText = selectedText {
            let activityViewController = UIActivityViewController(activityItems: [selectedText], applicationActivities: nil)
            
            activityViewController.modalTransitionStyle = .coverVertical
            activityViewController.popoverPresentationController?.sourceView = self.view
            activityViewController.popoverPresentationController?.sourceRect = self.view.bounds
            
            self.present(activityViewController, animated: true, completion: nil)
        }
    }
    
    // Performaction copy and share
    @objc override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        super.canPerformAction(action, withSender: sender)
        guard let selectedText = selectedText, !selectedText.isEmpty else {
            return false
        }
        
        if action == #selector(self.copy(_:)) || action == #selector(self.share(_:)) {
            return true
        }
        
        return false
    }
    
    // Need override to show UIMenuController
    override var canBecomeFirstResponder: Bool {
        
        if let selectedText = selectedText, !selectedText.isEmpty {
            return !isPresentPhotoLibrary
        }
        
        return isPresentPhotoLibrary
    }
    
}


extension CKRoomViewController {
    
    private func forceUpdateMemberInRoom() {
        
        // Sync room members from server to fix bug:
        // The membersCount is differrent between before and after load from MXKRoomDataSourceManager
        roomDataSource?.room.members({ [weak self] (members) in
            if let newJoinedCount = members?.joinedMembers.count {
                self?.roomDataSource?.room.summary.membersCount.joined = UInt(newJoinedCount)
                self?.roomDataSource?.delegate.dataSource(self?.roomDataSource, didCellChange: nil)
            }
            }, lazyLoadedMembers: { (_) in
                //
        }, failure: { (error) in
            print("Sync room members failed ")
        })
    }
    
    private func openDocumentWindow() {
        documentPickerPresenter.delegate = self
        documentPickerPresenter.presentDocumentPicker(with: [MXKUTI.data], from: self, animated: true) {
        }
    }
}

extension CKRoomViewController: MXKDocumentPickerPresenterDelegate {
    func documentPickerPresenterWasCancelled(_ presenter: MXKDocumentPickerPresenter) {
        print("cancel picking")
    }
    
    func documentPickerPresenter(_ presenter: MXKDocumentPickerPresenter, didPickDocumentsAt url: URL) {
        guard let fileUTI = MXKUTI.init(localFileURL: url) else {
            let alert = UIAlertController.init(title: nil, message: "Cannot load file", preferredStyle: .alert)
            alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: { (action) in
            }))
            alert.presentGlobally(animated: true, completion: nil)

            return
        }
        guard let mimeType = fileUTI.mimeType else {
            let alert = UIAlertController.init(title: nil, message: "Unsupported file", preferredStyle: .alert)
            alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: { (action) in
            }))
            alert.presentGlobally(animated: true, completion: nil)
            
            return
        }
        if let data = try? Data(contentsOf: url) {
            if fileUTI.isImage {
                self.customizedRoomDataSource?.sendImage(data, mimeType: mimeType, success: nil, failure: { (error) in
                    print("Send image failed")
                })
            } else if fileUTI.isVideo {
                self.getThumbnailImageFromVideoUrl(url: url) { (image) in
                    let thumbnail = (image != nil) ? image : UIImage()
                    self.customizedRoomDataSource?.sendVideo(url, withThumbnail: thumbnail, success: nil, failure: { (error) in
                        print("Send video failed")
                    })
                }
            } else if fileUTI.isFile {
                self.customizedRoomDataSource?.sendFile(url, mimeType: mimeType, success: nil, failure: { (error) in
                    print("Send file failed")
                })
            }
        }
    }
    
    func getThumbnailImageFromVideoUrl(url: URL, completion: @escaping ((_ image: UIImage?)->Void)) {
        DispatchQueue.global().async {
            let asset = AVAsset(url: url)
            let avAssetImageGenerator = AVAssetImageGenerator(asset: asset)
            avAssetImageGenerator.appliesPreferredTrackTransform = true
            let thumnailTime = CMTimeMake(2, 1)
            do {
                let cgThumbImage = try avAssetImageGenerator.copyCGImage(at: thumnailTime, actualTime: nil)
                let thumbImage = UIImage(cgImage: cgThumbImage)
                DispatchQueue.main.async {
                    completion(thumbImage)
                }
            } catch {
                print(error.localizedDescription)
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
}

// MARK: Overight methed keyboard
extension CKRoomViewController {
    
    @objc func onKeyboardWillShow(_ notification: Notification) {

        if let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            
            let keyboardRectangle = keyboardFrame.cgRectValue
            let height = keyboardRectangle.height - self.safeArea.bottom
            
            if self.roomInputToolbarContainerBottomConstraint.constant != height {
                self.roomInputToolbarContainerBottomConstraint.constant = height
                self.forceScrollBottom()
            }
        }
    }
    
    
    @objc func onKeyboardWillHide(_ notification: Notification) {
        
        self.keyboardView = nil
        
        let animationCurve: UInt? = notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? UInt
        
        let animationDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
        
        let options = UIViewAnimationOptions(rawValue: (animationCurve ?? 0) << 16)
        UIView.animate(withDuration: animationDuration, delay: 0, options: options, animations: {
            
            self.roomInputToolbarContainerBottomConstraint.constant = 0
        }) { (finish) in
//            self.view.endEditing(true)
        }
        
    }

    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
    }
    
    private func forceScrollBottom() {
        
        guard let tableview = self.bubblesTableView else {
            return
        }

        if (roomContextualMenuPresenter?.isPresenting ?? false) {
            return
        }

        let bottomInputToolbar: CGFloat = self.roomInputToolbarContainerBottomConstraint.constant
        
        let visibleHeight = tableview.frame.height - tableview.mxk_adjustedContentInset.top - tableview.mxk_adjustedContentInset.bottom
        
        let currentOffsetY = tableview.contentOffset.y
        
        if visibleHeight < tableview.contentSize.height {
            if currentOffsetY + bottomInputToolbar < tableview.contentSize.height {
                tableview.scrollToBottom(bottomInputToolbar)
            }
        } else {
            if bottomInputToolbar - tableview.contentSize.height < 0 {
                tableview.scrollToBottom(bottomInputToolbar)
            }
        }
    }
    
    // -- detect first access photo, force reload image picker
    @objc private func applicationDidBecomeActive(_ notification: Notification) {
        
        if currentInputView != nil && isPresentPhotoLibrary {
            imagePickerController?.collectionView.reloadData()
        }
    }
}


// MARK: Contextual Menu

extension CKRoomViewController {
    
    func contextualMenuItems(for event: MXEvent?, andCell cell: MXKCellRendering?) -> [RoomContextualMenuItem]? {

        return []
    }

    func showContextualMenu(for event: MXEvent?, fromSingleTapGesture usedSingleTapGesture: Bool, cell: MXKCellRendering?, animated: Bool) {
        if roomContextualMenuPresenter?.isPresenting ?? false {
            return
        }
        guard let selectedEventId = event?.eventId, let roomId = roomDataSource.roomId else {
            return
        }
        
        var reactionsMenuViewModel: ReactionsMenuViewModel?
        var bubbleComponentFrameInOverlayView = CGRect.null
        if (cell is MXKRoomBubbleTableViewCell) && roomDataSource.canReactToEvent(withId: event?.eventId) {
            let roomBubbleTableViewCell = cell as? MXKRoomBubbleTableViewCell
            let bubbleCellData = roomBubbleTableViewCell?.bubbleData
            let bubbleComponents = bubbleCellData?.bubbleComponents
            let foundComponentIndex = bubbleCellData?.bubbleComponentIndex(forEventId: event?.eventId) ?? 0
            var bubbleComponentFrame: CGRect
            
            if (bubbleComponents?.count ?? 0) > 0 {
                let selectedComponentIndex = foundComponentIndex != NSNotFound ? foundComponentIndex : 0
                bubbleComponentFrame = roomBubbleTableViewCell?.surroundingFrameInTableView(forComponentIndex: selectedComponentIndex) ?? CGRect.zero
            } else {
                bubbleComponentFrame = roomBubbleTableViewCell?.frame ?? CGRect.zero
            }
            
            bubbleComponentFrameInOverlayView = bubblesTableView.convert(bubbleComponentFrame, to: overlayContainerView)
            let aggregations = mainSession.aggregations
            let aggregatedReactions = aggregations?.aggregatedReactions(onEvent: selectedEventId, inRoom: roomId)
            
            reactionsMenuViewModel = ReactionsMenuViewModel(aggregatedReactions: aggregatedReactions, eventId: selectedEventId)
            reactionsMenuViewModel?.coordinatorDelegate = self
        }
        
        if roomContextualMenuViewController == nil {
            roomContextualMenuViewController = RoomContextualMenuViewController.instantiate()
            roomContextualMenuViewController?.delegate = self
        }
        
        if let model = reactionsMenuViewModel {
            roomContextualMenuViewController?.update(reactionsMenuViewModel: model)
            self.enableOverlayContainerUserInteractions(true)
            roomContextualMenuPresenter?.present(roomContextualMenuViewController: roomContextualMenuViewController!,
                                                 from: self,
                                                 on: overlayContainerView,
                                                 contentToReactFrame: bubbleComponentFrameInOverlayView,
                                                 fromSingleTapGesture: usedSingleTapGesture,
                                                 animated: animated, completion: {
                                                    self.selectEvent(withId: selectedEventId)
            })
        }
    }
    
    func hideContextualMenu(animated: Bool) {
        
        hideContextualMenu(animated: animated) { }
    }
    
    func hideContextualMenu(animated: Bool, completion: @escaping () -> Void) {
        hideContextualMenu(animated: animated, cancelEventSelection: true, completion: completion)
    }

    func hideContextualMenu(animated: Bool, cancelEventSelection: Bool, completion: @escaping () -> Void) {
        if !(roomContextualMenuPresenter?.isPresenting ?? false) {
            return
        }
        
        if cancelEventSelection {
            self.cancelEventSelection()
        }
        
        roomContextualMenuPresenter?.hideContextualMenu(animated: animated, completion: {
            self.enableOverlayContainerUserInteractions(false)
            completion()
        })
    }

    func enableOverlayContainerUserInteractions(_ enableOverlayContainerUserInteractions: Bool) {
        bubblesTableView.scrollsToTop = !enableOverlayContainerUserInteractions
        overlayContainerView.isUserInteractionEnabled = enableOverlayContainerUserInteractions
    }
}

// MARK: ReactionsMenuViewModelCoordinatorDelegate
extension CKRoomViewController: ReactionsMenuViewModelCoordinatorDelegate {
    
    func reactionsMenuViewModel(_ viewModel: ReactionsMenuViewModel, didAddReaction reaction: String, forEventId eventId: String) {
        self.hideContextualMenu(animated: true) {
            self.roomDataSource.addReaction(reaction, forEventId: eventId, success: {
                print("ReactionsMenuViewModel add reaction success!")
            }, failure: { (error) in
                print("ReactionsMenuViewModel Fail: \(error?.localizedDescription ?? "")")
            })
        }
    }
    
    func reactionsMenuViewModel(_ viewModel: ReactionsMenuViewModel, didRemoveReaction reaction: String, forEventId eventId: String) {
        self.hideContextualMenu(animated: true) {
            self.roomDataSource.removeReaction(reaction, forEventId: eventId, success: {
                print("ReactionsMenuViewModel remove reaction success!")
            }, failure: { (error) in
                print("ReactionsMenuViewModel Fail: \(error?.localizedDescription ?? "")")
            })
        }
    }
    
    func reactionsMenuViewModelDidTapMoreReactions(_ viewModel: ReactionsMenuViewModel, forEventId eventId: String) {
        
        self.hideContextualMenu(animated: true)
        
        let emojiPickerCoordinatorBridgePresenter = EmojiPickerCoordinatorBridgePresenter(session: mainSession, roomId: roomDataSource.roomId, eventId: eventId)
        emojiPickerCoordinatorBridgePresenter.delegate = self
        
        let cellRow = roomDataSource.indexOfCellData(withEventId: eventId)
        
        var sourceView: UIView?
        var sourceRect = CGRect.null
        
        if cellRow >= 0 {
            let cellIndexPath = IndexPath(row: cellRow, section: 0)
            let cell = bubblesTableView.cellForRow(at: cellIndexPath)
            sourceView = cell
            
            if (cell is MXKRoomBubbleTableViewCell) {
                let roomBubbleTableViewCell = cell as? MXKRoomBubbleTableViewCell
                let bubbleComponentIndex = roomBubbleTableViewCell?.bubbleData.bubbleComponentIndex(forEventId: eventId) ?? 0
                sourceRect = roomBubbleTableViewCell?.componentFrameInContentView(for: bubbleComponentIndex) ?? CGRect.zero
            }
        }
        
        emojiPickerCoordinatorBridgePresenter.present(from: self, sourceView: sourceView, sourceRect: sourceRect, animated: true)
        self.emojiPickerCoordinatorBridgePresenter = emojiPickerCoordinatorBridgePresenter
    }
    
}

// MARK: RoomContextualMenuViewControllerDelegate
extension CKRoomViewController: RoomContextualMenuViewControllerDelegate {
    
    func roomContextualMenuViewControllerDidTapBackgroundOverlay(_ viewController: RoomContextualMenuViewController) {
        self.hideContextualMenu(animated: true)
    }
}


// MARK: EmojiPickerCoordinatorBridgePresenterDelegate
extension CKRoomViewController: EmojiPickerCoordinatorBridgePresenterDelegate {
    
    func emojiPickerCoordinatorBridgePresenter(_ coordinatorBridgePresenter: EmojiPickerCoordinatorBridgePresenter, didAddEmoji emoji: String, forEventId eventId: String) {
        
        coordinatorBridgePresenter.dismiss(animated: true) {
            
            self.roomDataSource.addReaction(emoji, forEventId: eventId, success: {
                
            }, failure: { (error) in
                print("emojiPickerCoordinatorBridgePresenter Add Fail: \(error?.localizedDescription ?? "")")
            })
        }
        
        self.emojiPickerCoordinatorBridgePresenter = nil
    }
    
    func emojiPickerCoordinatorBridgePresenter(_ coordinatorBridgePresenter: EmojiPickerCoordinatorBridgePresenter, didRemoveEmoji emoji: String, forEventId eventId: String) {
        
        coordinatorBridgePresenter.dismiss(animated: true) {
            
            self.roomDataSource.removeReaction(emoji, forEventId: eventId, success: {
                
            }, failure: { (error) in
                print("emojiPickerCoordinatorBridgePresenter Remove Fail: \(error?.localizedDescription ?? "")")
            })
        }
        
        self.emojiPickerCoordinatorBridgePresenter = nil
    }
    
    func emojiPickerCoordinatorBridgePresenterDidCancel(_ coordinatorBridgePresenter: EmojiPickerCoordinatorBridgePresenter) {
        
        coordinatorBridgePresenter.dismiss(animated: true, completion: nil)
        self.emojiPickerCoordinatorBridgePresenter = nil
    }
}
