//
//  CKRoomSettingsViewController.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/7/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKRoomSettingsViewController: MXKRoomSettingsViewController {
        
    enum TableViewSectionType {
        case infoRoom
        case dataSettings
    }
    
    var tblSections: [TableViewSectionType] = [.infoRoom, .dataSettings]
    
    public override class func nib() -> UINib? {
        return UINib.init(
            nibName: String(describing: CKRoomSettingsViewController.self),
            bundle: Bundle(for: self))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = String.ck_LocalizedString(key: "Info")
        setupTableView()
    }
    
    func setupTableView()  {
        
        tableView.register(UINib.init(nibName: "CKRoomNameCell", bundle: nil), forCellReuseIdentifier: "CKRoomNameCell")
        tableView.register(UINib.init(nibName: "CKTopicCell", bundle: nil), forCellReuseIdentifier: "CKTopicCell")
        tableView.register(UINib.init(nibName: "CKMembersCell", bundle: nil), forCellReuseIdentifier: "CKMembersCell")
        tableView.register(UINib.init(nibName: "CKFilesCell", bundle: nil), forCellReuseIdentifier: "CKFilesCell")
        tableView.register(UINib.init(nibName: "CKMoreSettingsCell", bundle: nil), forCellReuseIdentifier: "CKMoreSettingsCell")
        tableView.register(UINib.init(nibName: "CKAddPeopleCell", bundle: nil), forCellReuseIdentifier: "CKAddPeopleCell")
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
        reloadTableView()
    }
    
    
    func reloadTableView() {
        tblSections = [.infoRoom, .dataSettings]
        tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return tblSections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionType = tblSections[section]
        switch sectionType {
        case .infoRoom:
            return 2
        case .dataSettings:
            return 4
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionType = tblSections[indexPath.section]
        switch sectionType {
        case .infoRoom:
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "CKRoomNameCell" , for: indexPath)
                return cell
            } else if indexPath.row == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "CKTopicCell" , for: indexPath)
                return cell
            } else {
                return UITableViewCell()
            }
        case .dataSettings:
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "CKMembersCell", for: indexPath)
                return cell
            } else if indexPath.row == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "CKFilesCell", for: indexPath)
                return cell
            } else if indexPath.row == 2 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "CKMoreSettingsCell", for: indexPath)
                return cell
            } else if indexPath.row == 3 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "CKAddPeopleCell", for: indexPath)
                return cell
            }
            else {
                return UITableViewCell()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = #colorLiteral(red: 0.9763854146, green: 0.9765253663, blue: 0.9763547778, alpha: 1)
        return view
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let sectionType = tblSections[section]
        switch sectionType {
        case.infoRoom:
            return 40
        case.dataSettings:
            return 40
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let sectionType = tblSections[indexPath.section]
        switch sectionType {
        case .infoRoom:
            if indexPath.row == 1 {
                return tableView.rowHeight
            }
        default:
            return 60
        }
        return 60
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView.init()
        view.backgroundColor = UIColor.clear
        return view
    }    
}

