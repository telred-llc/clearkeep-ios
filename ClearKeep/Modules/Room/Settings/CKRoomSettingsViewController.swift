//
//  CKRoomSettingsViewController.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/7/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

@objc class CKRoomSettingsViewController: MXKRoomSettingsViewController {
    
    // MARK: - PROPERTY
    
    /**
     TableView Section Type
     */
    enum TableViewSectionType {
        case infos
        case settings
        case actions
    }

    /**
     Cells heigh
     */
    private let kInfoCellHeigh: CGFloat     = 80.0
    private let kDefaultCellHeigh: CGFloat  = 60.0
    
    /**
     tblSections
     */
    private var tblSections: [TableViewSectionType] = [.infos, .settings, .actions]
    
    /**
     extraEventsListener
     */
    private var extraEventsListener: Any!
    
    /**
     mxRoom
     */
    private var mxRoom: MXRoom! {
        return self.value(forKey: "mxRoom") as? MXRoom
    }
    
    /**
     mxRoomState
     */
    private var mxRoomState: MXRoomState! {
        return self.value(forKey: "mxRoomState") as? MXRoomState
    }    
    
    // MARK: - CLASS
    
    public override class func nib() -> UINib? {
        return UINib.init(
            nibName: String(describing: CKRoomSettingsViewController.self),
            bundle: Bundle(for: self))
    }
    
    // MARK: - PRIVATE
    
    private func setupTableView()  {
        
        self.tableView.register(CKRoomSettingsRoomNameCell.nib, forCellReuseIdentifier: CKRoomSettingsRoomNameCell.identifier)
        self.tableView.register(CKRoomSettingsTopicCell.nib, forCellReuseIdentifier: CKRoomSettingsTopicCell.identifier)
        self.tableView.register(CKRoomSettingsMembersCell.nib, forCellReuseIdentifier: CKRoomSettingsMembersCell.identifier)
        self.tableView.register(CKRoomSettingsFilesCell.nib, forCellReuseIdentifier: CKRoomSettingsFilesCell.identifier)
        self.tableView.register(CKRoomSettingsMoreSettingsCell.nib, forCellReuseIdentifier: CKRoomSettingsMoreSettingsCell.identifier)
        self.tableView.register(CKRoomSettingsAddPeopleCell.nib, forCellReuseIdentifier: CKRoomSettingsAddPeopleCell.identifier)

        self.tableView.estimatedRowHeight = 100
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.backgroundColor = #colorLiteral(red: 0.9763854146, green: 0.9765253663, blue: 0.9763547778, alpha: 1)
        self.view.backgroundColor = #colorLiteral(red: 0.9763854146, green: 0.9765253663, blue: 0.9763547778, alpha: 1)
        self.navigationItem.title = String.ck_LocalizedString(key: "Info")
        self.reloadTableView()
    }
    
    private func reloadTableView() {
        tblSections = [.infos, .settings, .actions]
        tableView.reloadData()
    }
    
    private func reflectDataUI() {
        self.tableView.reloadData()
    }
    
    private func dequeueReusableRoomNameCell(_ indexPath: IndexPath) -> CKRoomSettingsRoomNameCell! {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: CKRoomSettingsRoomNameCell.identifier ,
            for: indexPath) as! CKRoomSettingsRoomNameCell
        
        cell.roomnameLabel.text = (self.mxRoom != nil) ? "#\(self.mxRoom.summary.displayname!)" : "Set a name"
        return cell
    }
    
    private func dequeueReusableRoomTopicCell(_ indexPath: IndexPath) -> CKRoomSettingsTopicCell! {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: CKRoomSettingsTopicCell.identifier ,
            for: indexPath) as! CKRoomSettingsTopicCell
        
        if self.mxRoom != nil &&  self.mxRoom.summary.topic != nil {
            cell.enableEditTopic(false)
            cell.topicTextLabel.text = self.mxRoom.summary.topic
        } else {
            cell.enableEditTopic(true)
        }
        
        return cell
    }

    private func dequeueReusableRoomMembersCell(_ indexPath: IndexPath) -> CKRoomSettingsMembersCell! {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: CKRoomSettingsMembersCell.identifier ,
            for: indexPath) as! CKRoomSettingsMembersCell
        
        return cell
    }

    private func dequeueReusableRoomFilesCell(_ indexPath: IndexPath) -> CKRoomSettingsFilesCell! {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: CKRoomSettingsFilesCell.identifier ,
            for: indexPath) as! CKRoomSettingsFilesCell
        
        return cell
    }

    private func dequeueReusableRoomMoreSettingsCell(_ indexPath: IndexPath) -> CKRoomSettingsMoreSettingsCell! {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: CKRoomSettingsMoreSettingsCell.identifier ,
            for: indexPath) as! CKRoomSettingsMoreSettingsCell
        
        return cell
    }

    private func dequeueReusableRoomAddPeopleCell(_ indexPath: IndexPath) -> CKRoomSettingsAddPeopleCell! {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: CKRoomSettingsAddPeopleCell.identifier ,
            for: indexPath) as! CKRoomSettingsAddPeopleCell
        
        return cell
    }

    private func showsSettingsEdit() {

        // initialize vc from xib
        let vc = CKRoomSettingsEditViewController(
            nibName: "CKRoomSettingsEditViewController",
            bundle: nil)
        
        // import mx session and room id
        vc.importSession(self.mxSessions)
        vc.mxRoom = self.mxRoom
        
        // present vc
        let navi = UINavigationController.init(rootViewController: vc)
        self.present(navi, animated: true, completion: nil)
    }
    
    private func showParticiants() {
        
        // initialize vc from xib
        let vc = CKRoomSettingsParticipantViewController(
            nibName: "CKRoomSettingsParticipantViewController",
            bundle: nil)
        
        // import mx session and room id
        vc.importSession(self.mxSessions)
        vc.mxRoom = self.mxRoom

        // present vc
        let navi = UINavigationController.init(rootViewController: vc)
        self.present(navi, animated: true, completion: nil)
    }
    
    private func isInfosAvailableData() -> Bool {
        guard let room = self.mxRoom, let roomSummary = room.summary else {
            return false
        }
        
        return roomSummary.topic != nil
    }
    
    // MARK: - OVERRIDE
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.title = String.ck_LocalizedString(key: "Info")
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return tblSections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionType = tblSections[section]

        switch sectionType {
        case .infos:
            return self.isInfosAvailableData() ? 3 : 2
        case .settings:
            return 3
        case .actions:
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionType = tblSections[indexPath.section]
        
        switch sectionType {
        case .infos:
            if indexPath.row == 0 {
                return self.dequeueReusableRoomNameCell(indexPath)
            } else if indexPath.row == 1 {
                return self.dequeueReusableRoomTopicCell(indexPath)
            } else {
                let cell = UITableViewCell()
                cell.textLabel?.text = "Edit"
                cell.textLabel?.textAlignment = NSTextAlignment.center
                cell.textLabel?.textColor = CKColor.Text.lightBlueText
                return cell
            }
        case .settings:
            if indexPath.row == 0 {
                return self.dequeueReusableRoomMembersCell(indexPath)
            } else if indexPath.row == 1 {
                return self.dequeueReusableRoomFilesCell(indexPath)
            } else if indexPath.row == 2 {
                return self.dequeueReusableRoomMoreSettingsCell(indexPath)
            }
            else {
                return UITableViewCell()
            }
        case .actions:
            return self.dequeueReusableRoomAddPeopleCell(indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = CKColor.Background.tableView
        return view
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let sectionType = tblSections[section]
        switch sectionType {
        case .infos:
            return 40
        case .settings:
            return 10
        case .actions:
            return 10
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let sectionType = tblSections[indexPath.section]
        switch sectionType {
        case .infos:
            if indexPath.row == 1 {
                if (self.mxRoom != nil && mxRoom.summary.topic == nil) {
                    return kInfoCellHeigh
                }
                return UITableViewAutomaticDimension
            }
        default:
            return kDefaultCellHeigh
        }
        return kDefaultCellHeigh
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView.init()
        view.backgroundColor = UIColor.clear
        return view
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let sectionType = tblSections[indexPath.section]
        
        switch sectionType {
        case .infos:
            if indexPath.row == 1 || indexPath.row == 2 { self.showsSettingsEdit() }
        case .settings:
            if indexPath.row == 0 { self.showParticiants() }
            break
        case .actions:
            break
        }
    }
    
    override func initWith(_ session: MXSession!, andRoomId roomId: String!) {
        super.initWith(session, andRoomId: roomId)
        
        if let room = self.mxRoom {
            self.extraEventsListener = room.listen(
            toEventsOfTypes: [kMXEventTypeStringRoomMember]) { (event: MXEvent?, direction: __MXTimelineDirection, roomState: MXRoomState?) in
                self.update(roomState)
            }
        }
    }
    
    override func update(_ newRoomState: MXRoomState!) {
        super.update(newRoomState)
    }
}
