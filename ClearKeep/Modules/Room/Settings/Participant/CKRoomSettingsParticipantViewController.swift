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
    @IBOutlet weak var searchingBar: UISearchBar!
    
    // MARK: - PROPERTY
    
    /**
     MX Room
     */
    public var mxRoom: MXRoom!
    
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
        
        // bar button items
        let backItemButton = UIBarButtonItem.init(
            title: "Back",
            style: .plain, target: self,
            action: #selector(clickedOnBackButton(_:)))
        
        // assign left bar button item
        self.navigationItem.leftBarButtonItem = backItemButton
        
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
            self.tableView.reloadData()
        }
    }
    
    private func handle(roomMember member: MXRoomMember) {
        self.filteredParticipants.append(member)
    }
    
    private func showPersonalAccountProfile() {
        
        // initialize vc from xib
        let vc = CKAccountProfileViewController(
            nibName: "CKAccountProfileViewController",
            bundle: nil)
        
        // import mx session and room id
        vc.importSession(self.mxSessions)
        vc.mxRoom = self.mxRoom
        vc.mxNumber = self.filteredParticipants
        
        // present vc
        let navi = UINavigationController.init(rootViewController: vc)
        self.present(navi, animated: true, completion: nil)
    }
    
    // MARK: - ACTION
    
    @objc private func clickedOnBackButton(_ sender: Any?) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: - PUBLIC
}

// MARK: - UITableViewDelegate

extension CKRoomSettingsParticipantViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 0 {self.showPersonalAccountProfile()}
    }
}

// MARK: - UITableViewDataSource

extension CKRoomSettingsParticipantViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredParticipants != nil ? filteredParticipants.count : 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // de-cell
        if let cell = tableView.dequeueReusableCell(
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
        
        // default cell
        return UITableViewCell()
    }
    
    
}
