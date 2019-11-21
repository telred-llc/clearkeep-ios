//
//  CKRoomSettingsParticipantViewController.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/19/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKRoomSettingsParticipantViewController: MXKViewController {
    
    // MARK: - OUTLET
    
    @IBOutlet weak var tableView: UITableView!
    
    private enum Section: Int {
        case search = 0
        case participants = 1
        case invited = 2
        
        static func count() -> Int {
            return 2
        }
    }

    // MARK: - PROPERTY
    
    /**
     MX Room
     */
    public var mxRoom: MXRoom!
    private var mxRoomPowerLevels: MXRoomPowerLevels?
    
    /**
     Original data source
     */
    private var originalDataSource: [MXRoomMember]! = nil
    
    /**
     filtered out participants
     */
    private var filteredParticipants: [MXRoomMember]! = [MXRoomMember]() {
        didSet {
            listInvited = filteredParticipants.filter { $0.membership.identifier == __MXMembershipInvite }
            
            listParticipant = filteredParticipants.filter { $0.membership.identifier == __MXMembershipJoin }
            
            tableView.reloadData()
        }
    }
    
    private var listParticipant: [MXRoomMember] = []
    
    private var listInvited: [MXRoomMember] = []
    
    // List admin in room
    private var adminList = [String]()
    
    /**
     members Listener
     */
    private var membersListener: Any!
    
    // Observers
    private var removedAccountObserver: Any?
    private var accountUserInfoObserver: Any?
    private var pushInfoUpdateObserver: Any?
    
    private let kCkRoomAdminLevel = 100
    private let disposeBag = DisposeBag()
    
    // MARK: - OVERRIDE
    
    override func destroy() {
        if pushInfoUpdateObserver != nil {
            NotificationCenter.default.removeObserver(pushInfoUpdateObserver!)
            pushInfoUpdateObserver = nil
        }
        
        if accountUserInfoObserver != nil {
            NotificationCenter.default.removeObserver(accountUserInfoObserver!)
            accountUserInfoObserver = nil
        }
        
        if removedAccountObserver != nil {
            NotificationCenter.default.removeObserver(removedAccountObserver!)
            removedAccountObserver = nil
        }
        
        super.destroy()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.finalizeLoadView()
        
        // Add observer to handle removed accounts
        removedAccountObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.mxkAccountManagerDidRemoveAccount, object: nil, queue: OperationQueue.main, using: { notif in
            // Refresh table to remove this account
            self.reloadParticipantsInRoom()
        })
        
        // Add observer to handle accounts update
        accountUserInfoObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.mxkAccountUserInfoDidChange, object: nil, queue: OperationQueue.main, using: { notif in
            
            self.stopActivityIndicator()
            self.reloadParticipantsInRoom()
        })
        
        // Add observer to push settings
        pushInfoUpdateObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.mxkAccountPushKitActivityDidChange, object: nil, queue: OperationQueue.main, using: { notif in
            
            self.stopActivityIndicator()
            self.reloadParticipantsInRoom()
        })
    }
    
    // MARK: - PRIVATE
    
    private func finalizeLoadView() {
        
        // title
        self.navigationItem.title = CKLocalization.string(byKey: "room_setting_participant_title")
        
        // register cells
        self.tableView.register(
            CKRoomSettingsParticipantCell.nib,
            forCellReuseIdentifier: CKRoomSettingsParticipantCell.identifier)
        self.tableView.register(
            CKRoomSettingsParticipantSearchCell.nib,
            forCellReuseIdentifier: CKRoomSettingsParticipantSearchCell.identifier)        
        
        // invoke timeline event
        self.liveTimelineEvents()
        
        // reload
        self.reloadParticipantsInRoom()

        bindingTheme()
        
        addCustomBackButton()
    }

    func bindingTheme() {
        // Binding navigation bar color
        themeService.attrsStream.subscribe(onNext: { [weak self] (theme) in
            self?.defaultBarTintColor = themeService.attrs.navBarBgColor
            self?.barTitleColor = themeService.attrs.navBarTintColor
            self?.tableView.reloadData()
        }).disposed(by: disposeBag)

        themeService.rx
            .bind({ $0.primaryBgColor }, to: view.rx.backgroundColor, tableView.rx.backgroundColor)
            .disposed(by: disposeBag)
    }

    private func liveTimelineEvents() {
        
        // event of types
        let eventsOfTypes = [MXEventType.roomMember,
                             MXEventType.roomThirdPartyInvite,
                             MXEventType.roomPowerLevels]
        
        // list members
        self.mxRoom.liveTimeline { (liveTimeline: MXEventTimeline?) in
            
            // guard
            guard let liveTimeline = liveTimeline else {
                return
            }
            
            // timeline listen to events
            self.membersListener = liveTimeline.listenToEvents(eventsOfTypes, { (event: MXEvent, direction: MXTimelineDirection, state: MXRoomState) in
                
                // direction
                if direction == MXTimelineDirection.forwards {
                    
                    // case in room member
                    switch event.eventType {
                    case __MXEventTypeRoomMember:
                        
                        // ignore current user who is as a member
                        if event.stateKey != self.mxRoom.mxSession.myUser.userId {
                            
                            // ask to init mx member
                            if let mxMember = liveTimeline.state.members.member(withUserId: event.stateKey) {
                                
                                // handle member
                                self.handle(roomMember: mxMember)
                                self.getAdmin(state: liveTimeline.state, member: mxMember)
                            }
                            
                            // finalize room member state
                            self.finalizeReloadingParticipants(state)
                        }
                        
                    case __MXEventTypeRoomPowerLevels:
                        self.reloadParticipantsInRoom()
                        
                    default:
                        break
                    }
                    
                }
            })
        }
    }
    
    private func reloadParticipantsInRoom() {
        
        // reset
        self.filteredParticipants.removeAll()
        
        // room state
        self.mxRoom.state { (state: MXRoomState?) in
            self.mxRoomPowerLevels = state?.powerLevels
            // try to get members
            if let members = state?.members.membersWithoutConferenceUser() {
                
                // handl each member
                for m in members {
                    self.handle(roomMember: m)
                    self.getAdmin(state: state, member: m)
                }
                
                // finalize room member state
                self.finalizeReloadingParticipants(state!)
            }
        }
    }
    
    private func getAdmin(state: MXRoomState?, member: MXRoomMember) {
        // power lever is admin
        guard let state = state, let powerLevels = state.powerLevels else {
            return
        }
        
        if powerLevels.powerLevelOfUser(withUserID: member.userId) >= self.kCkRoomAdminLevel {
            adminList.append(member.userId)
        }
    }
    
    private func finalizeReloadingParticipants(_ state: MXRoomState) {
        DispatchQueue.main.async {
            self.originalDataSource = self.filteredParticipants
        }
    }
    
    private func handle(roomMember member: MXRoomMember) {
      
        self.filteredParticipants = self.filteredParticipants.filter { $0.userId != member.userId }
        
        self.filteredParticipants.append(member)
    }
    
    private func showPersonalAccountProfile() {
        
        // initialize vc from xib
        let vc = CKAccountProfileViewController(
            nibName: CKAccountProfileViewController.nibName,
            bundle: nil)
        
        // import mx session and room id
        vc.importSession(self.mxSessions)
        
        vc.mxRoomPowerLevels = mxRoomPowerLevels
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func showOthersAccountProfile(mxMember: MXRoomMember) {
        
        // initialize vc from xib
        let vc = CKOtherProfileViewController(
            nibName: CKOtherProfileViewController.nibName,
            bundle: nil)
        
        // import mx session and room id
        vc.importSession(self.mxSessions)
        vc.mxMember = mxMember
        vc.mxRoom = mxRoom
        vc.mxRoomPowerLevels = mxRoomPowerLevels
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func titleForHeader(atSection section: Int) -> String {
        guard let s = Section(rawValue: section) else { return ""}
        switch s {
        case .search:
            return ""
        case .participants:
            return self.listParticipant.isEmpty ? CKLocalization.string(byKey: "room_setting_participant_invite").uppercased() : CKLocalization.string(byKey: "room_setting_participant_title").uppercased()
        case .invited:
            return CKLocalization.string(byKey: "room_setting_participant_invite").uppercased()
        }
    }

    // MARK: - ACTION
    
    @objc private func clickedOnBackButton(_ sender: Any?) {
        if let nvc = self.navigationController {
            nvc.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }


    // MARK: - PUBLIC
}

// MARK: - UITableViewDelegate

extension CKRoomSettingsParticipantViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let s = Section(rawValue: indexPath.section) else { return 1}
        switch s {
        case .search:
            return CKLayoutSize.Table.row70px
        default:
            return CKLayoutSize.Table.row80px
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let section = Section(rawValue: indexPath.section) else { return }
        
        switch section {
        case .search:
            return
        case .participants:
            let mxMember = self.listParticipant.isEmpty ? listInvited[indexPath.row]: listParticipant[indexPath.row]
            if mxMember.userId == mainSession.myUser.userId {
                self.showPersonalAccountProfile()
            } else {
                self.showOthersAccountProfile(mxMember: mxMember)
            }
        case .invited:
            let mxMember = listInvited[indexPath.row]
            self.showOthersAccountProfile(mxMember: mxMember)
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let view = CKRoomHeaderInSectionView.instance() {
            view.theme.backgroundColor = themeService.attrStream{ $0.tblHeaderBgColor }
            view.descriptionLabel.theme.textColor = themeService.attrStream{ $0.primaryTextColor }
            view.descriptionLabel?.text = self.titleForHeader(atSection: section)
            return view
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UILabel()
        view.theme.backgroundColor = themeService.attrStream{ $0.secondBgColor }
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let s = Section(rawValue: section) else { return 1}
        switch s {
        case .search:
            return CGFloat.leastNonzeroMagnitude
        default:
            return CKLayoutSize.Table.defaultHeader
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }
}

// MARK: - UITableViewDataSource

extension CKRoomSettingsParticipantViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        var result: Int = 1
        
        if !listParticipant.isEmpty {
            result += 1
        }
        
        if !listInvited.isEmpty {
            result += 1
        }
        
        return result
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let s = Section(rawValue: section) else { return 0}
        switch s {
        case .search:
            return 1
        case .participants:
            return listParticipant.isEmpty ? listInvited.count : listParticipant.count
        case .invited:
            return listInvited.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let s = Section(rawValue: indexPath.section) else { return CKRoomSettingsBaseCell()}
        
        switch s {
        case .search:
            return cellForParticipantSearch(atIndexPath: indexPath)
        case .participants:
            let flagInvited: Bool = listParticipant.isEmpty
            return cellForParticipant(atIndexPath: indexPath, isInvited: flagInvited)
        case .invited:
            return cellForParticipant(atIndexPath: indexPath, isInvited: true)
        }
    }
    
    private func cellForParticipant(atIndexPath indexPath: IndexPath, isInvited: Bool = false) -> CKRoomSettingsParticipantCell {
        
        // de-cell
        if let cell = self.tableView.dequeueReusableCell(
            withIdentifier: CKRoomSettingsParticipantCell.identifier,
            for: indexPath) as? CKRoomSettingsParticipantCell {
            
            // pick index of member
            let mxMember = isInvited ? self.listInvited[indexPath.row] : self.listParticipant[indexPath.row]
            
            // fill fields to cell
            cell.participantLabel.text = mxMember.displayname ?? mxMember.userId
            cell.isAdmin = adminList.contains(mxMember.userId)
            cell.participantLabel.backgroundColor = UIColor.clear
            
            // avt
            cell.setAvatarUri(
                mxMember.avatarUrl,
                identifyText: mxMember.userId,
                session: self.mainSession)
            
            // status
            if let u = self.mainSession?.user(
                withUserId: mxMember.userId ?? "") {
                cell.status = u.presence == MXPresenceOnline ? 1 : 0
            } else { cell.status = 0 }

            cell.participantLabel.theme.textColor = themeService.attrStream{ $0.primaryTextColor }
            cell.roomAdminLabel.theme.textColor = themeService.attrStream{ $0.primaryTextColor }
            cell.theme.backgroundColor = themeService.attrStream{ $0.primaryBgColor }

            return cell
        }
        
        return CKRoomSettingsParticipantCell()
    }
    
    private func cellForParticipantSearch(atIndexPath indexPath: IndexPath) -> CKRoomSettingsParticipantSearchCell{
        
        // deque cell
        let cell = self.tableView.dequeueReusableCell(
            withIdentifier: CKRoomSettingsParticipantSearchCell.identifier,
            for: indexPath) as! CKRoomSettingsParticipantSearchCell
        
        // handle searching
        cell.beginSearchingHandler = { text in
            
            if text.count > 0 {
                self.filteredParticipants = self.originalDataSource.filter({ (member: MXRoomMember) -> Bool in
                    if let displayname = member.displayname {
                        return displayname.lowercased().contains(text.lowercased())
                    } else {
                        return member.userId.lowercased().contains(text.lowercased())
                    }
                })
            } else {
                self.filteredParticipants = self.originalDataSource
            }
            
        }

        cell.contentView.theme.backgroundColor = themeService.attrStream{ $0.primaryBgColor }
        cell.theme.backgroundColor = themeService.attrStream{ $0.primaryBgColor }
        
        return cell
    }
    
    // MARK: - PUBLIC
}
