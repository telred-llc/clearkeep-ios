//
//  CKRoomSettingsMoreSecurityViewController.swift
//  Riot
//
//  Created by Sinbad Flyce on 2/20/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKRoomSettingsMoreSecurityViewController: MXKViewController {
    
    // MARK: - OULTET
    
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - ENUM
    
    private enum Section: Int {
        case access = 0
        case read = 1
        
        static func count() -> Int {
            return 2
        }
    }

    // MARK: - STRUCT
    
    private struct SecurityOption {
        var description: String
        var isSelected: Bool
        var mxRule: MXRoomJoinRule
    }
    
    /**
     DataSource for UI
     */
    private var dataSource: [Int:[String:[String]]] = [
        Section.access.rawValue :
            ["Who can access this room?":
                ["Only people who have been invited",
                 "Anyone who knows the room's link, apart from guests",
                 "Anyone who knows the room's link, including guests"]],
        Section.read.rawValue :
            ["Who can read history?":
                ["Anyone",
                 "Members only (since the point in time of selecting this option)",
                 "Members only (since they were invited)",
                 "Members only (since they joined)"]]
    ]
    
    // MARK: - PROPERTY
    
    public var mxRoom: MXRoom!
    
    // MARK: - OVERRIDE
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.reloadData()
        self.tableView.register(CKRoomSettingsMoreSecurityRadioCell.nib, forCellReuseIdentifier: CKRoomSettingsMoreSecurityRadioCell.identifier)
        self.navigationItem.title = "Security"
        
        //self.mxRoom.setJoinRule(MXRoomJoinRule, completion: <#T##(MXResponse<Void>) -> Void#>)
    }
    
    // MARK: - PRIVATE
    
    private func cellForSecurityRadio(_ indexPath: IndexPath) -> CKRoomSettingsMoreSecurityRadioCell {
        let cell = self.tableView.dequeueReusableCell(
            withIdentifier: CKRoomSettingsMoreSecurityRadioCell.identifier, for: indexPath) as! CKRoomSettingsMoreSecurityRadioCell
        cell.textLabel?.text = self.stringForIndexPath(indexPath)
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
    
    // MARK: - PUBLIC
    
}

extension CKRoomSettingsMoreSecurityViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CKLayoutSize.Table.defaultHeader
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // TODO
        self.showAlert("Sorry! It should be coming soon")
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CKLayoutSize.Table.row60px
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let view = CKRoomHeaderInSectionView.instance() {
            view.backgroundColor = CKColor.Background.tableView
            view.descriptionLabel.text = self.stringForSection(section)?.uppercased()
            return view
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
}

extension CKRoomSettingsMoreSecurityViewController: UITableViewDataSource {
    
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
        return self.cellForSecurityRadio(indexPath)
    }
    
}
