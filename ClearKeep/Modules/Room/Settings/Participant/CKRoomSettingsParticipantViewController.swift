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
        
        static func count() -> Int {
            return 2
        }
    }

    // MARK: - PROPERTY
    
    /**
     MX Room
     */
    public var mxRoom: MXRoom!
    
    /**
     Original data source
     */
    private var originalDataSource: [MXRoomMember]! = nil
    
    /**
     filtered out participants
     */
    private var filteredParticipants: [MXRoomMember]! = [MXRoomMember]()
    
    /**
     members Listener
     */
    private var membersListener: Any!
    
    // MARK: - OVERRIDE
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.finalizeLoadView()
    }
    
    // MARK: - PRIVATE
    
    private func finalizeLoadView() {
        
        // title
        self.navigationItem.title = "Participants"
        
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
            
            // try to get members
            if let members = state?.members.membersWithoutConferenceUser() {
                
                // handl each member
                for m in members {
                    self.handle(roomMember: m)
                }
                
                // finalize room member state
                self.finalizeReloadingParticipants(state!)
            }
        }
    }
    
    private func finalizeReloadingParticipants(_ state: MXRoomState) {
        DispatchQueue.main.async {
            self.originalDataSource = self.filteredParticipants
            self.tableView.reloadData()
        }
    }
    
    private func handle(roomMember member: MXRoomMember) {
        self.filteredParticipants.append(member)
    }
    
//    private func showPersonalAccountProfile() {
//
//        // initialize vc from xib
//        let vc = CKAccountProfileViewController(
//            nibName: "CKAccountProfileViewController",
//            bundle: nil)
//
//        // import mx session and room id
//        vc.importSession(self.mxSessions)
//        vc.mxRoom = self.mxRoom
//        vc.mxNumber = self.filteredParticipants
//
//        // present vc
//        let navi = UINavigationController.init(rootViewController: vc)
//        self.present(navi, animated: true, completion: nil)
//    }
    
    private func showOthersAccountProfile() {
        
        // initialize vc from xib
        let vc = CKOtherProfileViewController(
            nibName: "CKOtherProfileViewController",
            bundle: nil)
        
        // import mx session and room id
        vc.importSession(self.mxSessions)
        vc.mxRoom = self.mxRoom
        vc.mxNumber = self.filteredParticipants
        
        // present vc
        let navi = UINavigationController.init(rootViewController: vc)
        self.present(navi, animated: true, completion: nil)
    }
    
    private func titleForHeader(atSection section: Int) -> String {
        guard let s = Section(rawValue: section) else { return ""}
        switch s {
        case .search:
            return ""
        case .participants:
            return "PARTICIPANTS"
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
            return CKLayoutSize.Table.row44px
        default:
            return CKLayoutSize.Table.row60px
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let mxMember = filteredParticipants[indexPath.row]
        if mxMember.userId == mainSession.myUser.userId {
            // initialize vc from xib
            let vc = CKAccountProfileViewController(
                nibName: "CKAccountProfileViewController",
                bundle: nil)
            
            // import mx session and room id
            vc.importSession(self.mxSessions)
            vc.mxRoom = self.mxRoom
            vc.mxMember = mxMember
            
            // present vc
            let navi = UINavigationController.init(rootViewController: vc)
            self.present(navi, animated: true, completion: nil)

        } else {
            // initialize vc from xib
            let vc = CKOtherProfileViewController(
                nibName: "CKOtherProfileViewController",
                bundle: nil)
            
            // import mx session and room id
            vc.importSession(self.mxSessions)
            vc.mxRoom = self.mxRoom
            vc.mxNumber = [mxMember]
            
            // present vc
            let navi = UINavigationController.init(rootViewController: vc)
            self.present(navi, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let view = CKRoomHeaderInSectionView.instance() {
            view.backgroundColor = CKColor.Background.tableView
            view.title = self.titleForHeader(atSection: section)
            return view
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UILabel()
        view.backgroundColor = CKColor.Background.tableView
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let s = Section(rawValue: section) else { return 1}
        switch s {
        case .search:
            return CKLayoutSize.Table.header1px
        default:
            return CKLayoutSize.Table.header40px
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CKLayoutSize.Table.footer1px
    }
}

// MARK: - UITableViewDataSource

extension CKRoomSettingsParticipantViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let s = Section(rawValue: section) else { return 0}
        switch s {
        case .search:
            return 1
        case .participants:
            return filteredParticipants != nil ? filteredParticipants.count : 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let s = Section(rawValue: indexPath.section) else { return CKRoomSettingsBaseCell()}
        
        switch s {
        case .search:
            return cellForParticipantSearch(atIndexPath: indexPath)
        case .participants:
            return cellForParticipant(atIndexPath: indexPath)
        }
    }
    
    private func cellForParticipant(atIndexPath indexPath: IndexPath) -> CKRoomSettingsParticipantCell {
        // de-cell
        if let cell = self.tableView.dequeueReusableCell(
            withIdentifier: CKRoomSettingsParticipantCell.identifier,
            for: indexPath) as? CKRoomSettingsParticipantCell {
            
            // pick index of member
            let mxMember = self.filteredParticipants[indexPath.row]
            
            // fill fields to cell
            cell.participantLabel.text = mxMember.displayname
            cell.participantLabel.backgroundColor = UIColor.clear
            cell.accessoryType = .disclosureIndicator
            
            if let avtURL = self.mainSession.matrixRestClient.url(ofContent: mxMember.avatarUrl) {
                cell.setAvatarImageUrl(urlString: avtURL, previewImage: nil)
            } else {
                cell.photoView.image = AvatarGenerator.generateAvatar(forText: mxMember.userId)
            }
            
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
                    return member.displayname.lowercased().contains(text.lowercased())
                })
            } else {
                self.filteredParticipants = self.originalDataSource
            }
            
            DispatchQueue.main.async(execute: {
                self.tableView.reloadData()
            })
        }
        return cell
    }
    
    // MARK: - PUBLIC
}
