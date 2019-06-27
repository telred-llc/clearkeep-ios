//
//  CKRoomSettingsMoreRoleViewController.swift
//  Riot
//
//  Created by Sinbad Flyce on 2/21/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKRoomSettingsMoreRoleViewController: MXKViewController {
    
    // MARK: - OUTLET
    
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - ENUM
    
    private enum Section: Int {
        case privileged = 0
        case permissions = 1
        static func count() -> Int { return 2 }
    }
    
    // MARK: - PROPERTY
    
    private let kCkRoomModeratorLevel = 50
    private let kCkRoomAdminLevel = 100
    private let disposeBag = DisposeBag()

    /**
     DataSource for UI
     */
    private var dataSource: [Int:[String:[String]]] = [
        Section.privileged.rawValue : [
            "Privileged Users": [String]()
        ],
        Section.permissions.rawValue: [
            "Permissions": [
                "The default role for new room members is Default",
                 "To send messages, you must be a Default",
                 "To invite users into the room, you must be a Default",
                 "To configure the room, you must be a Moderator",
                 "To kick users, you must be a Moderator",
                 "To ban users, you must be a Moderator",
                 // "To remove other users' messages, you must be a Moderator",
                 // "To notify everyone in the room, you must be a Moderator",
                 // "To change the room's main address, you must be a Moderator",
                 // "To change the room's history visibility, you must be a Admin",
                 "To change the room's avatar, you must be a Moderator",
                 // "To change the permissions in the room, you must be a Moderator",
                 "To change the room's name, you must be a Moderator",
                 "To change the topic, you must be a Moderator",
                 //"To modify widgets in the room, you must be a Moderator",
            ]
        ]
    ]
    
    public var mxRoom: MXRoom!
    
    // MARK: - OVERRIDE
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(CKRoomSettingsMoreRoleCell.nib, forCellReuseIdentifier: CKRoomSettingsMoreRoleCell.identifier)
        self.navigationItem.title = "Roles"
        
        // load priviledge
        self.loadPrivileged { (admins: [String]?) in
            
            guard let ads = admins else {
                return
            }
            // on main thread
            DispatchQueue.main.async {
                
                // update admins
                if let key = self.dataSource[Section.privileged.rawValue]?.keys.first {
                    self.dataSource[Section.privileged.rawValue]?[key] = ads
                }
                
                // reload
                self.tableView.reloadSections([Section.privileged.rawValue], with: .none)
            }
        }

        bindingTheme()
    }
    
    // MARK: - PRIVATE

    private func bindingTheme() {
        // Binding navigation bar color
        themeService.attrsStream.subscribe(onNext: { [weak self] (theme) in
            self?.defaultBarTintColor = themeService.attrs.primaryBgColor
            self?.barTitleColor = themeService.attrs.primaryTextColor
            self?.tableView.reloadData()
        }).disposed(by: disposeBag)

        themeService.rx
            .bind({ $0.secondBgColor }, to: view.rx.backgroundColor, tableView.rx.backgroundColor)
            .disposed(by: disposeBag)
    }

    /**
     Cell for roles
     */
    private func cellForRole(_ indexPath: IndexPath) -> CKRoomSettingsMoreRoleCell {
        
        // cell
        let cell = self.tableView.dequeueReusableCell(
            withIdentifier: CKRoomSettingsMoreRoleCell.identifier,
            for: indexPath) as! CKRoomSettingsMoreRoleCell
        
        // section
        let s = Section(rawValue: indexPath.section)!
        
        // cases in
        switch s {
        case .privileged:
            cell.selectionStyle = .none
        case .permissions:
            cell.selectionStyle = .default
        }
        
        cell.title = self.stringForIndexPath(indexPath)
        cell.titleLabel.theme.textColor = themeService.attrStream{ $0.primaryTextColor }
        cell.theme.backgroundColor = themeService.attrStream{ $0.secondBgColor }
        return cell
    }
    
    private func stringForSection(_ section: Int) -> String? {
        return self.dataSource[section]?.keys.first
    }
    
    private func stringForIndexPath(_ indexPath: IndexPath) -> String? {
        if let key = self.stringForSection(indexPath.section) {
            return self.dataSource[indexPath.section]?[key]?[indexPath.row]
        }
        return nil
    }

    private func loadPrivileged(completion: (([String]?) -> Void)? ) {
        
        // pull room's state
        self.mxRoom.state { (state: MXRoomState?) in
            
            // sure that
            guard let s = state else {
                
                // fallback error
                completion?(nil)
                return
            }
            
            // room members
            self.mxRoom?.members(completion: { (members: MXResponse<MXRoomMembers?>) in
                
                // sure that
                if let members = members.value??.members {
                    
                    // sure that
                    guard let powerLevels = s.powerLevels else {
                        completion?(nil)
                        return
                    }
                    
                    // admin-id members
                    var admins = [String]()
                    
                    // pick some admins
                    for m in members {
                        
                        // power lever is admin
                        if powerLevels.powerLevelOfUser(withUserID: m.userId) >= self.kCkRoomAdminLevel {
                            
                            // append it
                            admins.append(m.userId)
                        }
                    }
                    
                    // fallback ok
                    completion?(admins)
                }
                
                // fallback error
                completion?(nil)
            })
        }
    }
    
    // MARK: - PUBLIC
}

extension CKRoomSettingsMoreRoleViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CKLayoutSize.Table.defaultHeader
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let view = CKRoomHeaderInSectionView.instance() {
            view.descriptionLabel.text = self.stringForSection(section)?.uppercased()
            view.descriptionLabel.theme.textColor = themeService.attrStream{ $0.primaryTextColor }
            view.theme.backgroundColor = themeService.attrStream{ $0.tblHeaderBgColor }
            return view
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
}

extension CKRoomSettingsMoreRoleViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let key = self.stringForSection(section) {
            return self.dataSource[section]?[key]?.count ?? 0
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return self.cellForRole(indexPath)
    }
    
}
