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

    // MARK: - PROPERTY
    
    /**
     Admin permission of room
     */
    let kAdminPermission = 100
    
    /**
     Chooses to make checkmark
     */
    private var chooses = [Section.access.rawValue : 0,
                           Section.read.rawValue : 0]
    
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
    
    /**
     Room object
     */
    public var mxRoom: MXRoom!
    
    /**
     Power level of current user in this room
     */
    private var powerLevel: Int = 0

    private let disposeBag = DisposeBag()

    // MARK: - OVERRIDE
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.reloadData()
        self.tableView.register(CKRoomSettingsMoreSecurityRadioCell.nib, forCellReuseIdentifier: CKRoomSettingsMoreSecurityRadioCell.identifier)
        self.navigationItem.title = "Security"
        self.addCustomBackButton()
        self.loadPowerLevel()
        self.bindingTheme()
    }
    
    // MARK: - PRIVATE

    private func bindingTheme() {
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
    
    private func cellForSecurityRadio(_ indexPath: IndexPath) -> CKRoomSettingsMoreSecurityRadioCell {
        
        // dequeue cell
        let cell = self.tableView.dequeueReusableCell(
            withIdentifier: CKRoomSettingsMoreSecurityRadioCell.identifier, for: indexPath) as! CKRoomSettingsMoreSecurityRadioCell
        
        // fill cell
        cell.title = self.stringForIndexPath(indexPath)
        cell.tintColor = self.powerLevel >= kAdminPermission ? themeService.attrs.primaryTextColor : UIColor.lightGray
        cell.accessoryType = (self.chooses[indexPath.section] == indexPath.row) ? .checkmark : .none

        cell.titleLable.theme.textColor = themeService.attrStream{ $0.primaryTextColor }
        cell.theme.backgroundColor = themeService.attrStream{ $0.primaryBgColor }

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
    
    private func loadPowerLevel() {
        
        // room state
        self.mxRoom.state { (s: MXRoomState?) in
            
            // try to get power level
            let pl = s?.powerLevels?.powerLevelOfUser(
                withUserID: self.mainSession?.myUser?.userId) ?? 0
            
            // reload data
            DispatchQueue.main.async {
                self.powerLevel = pl
                self.tableView.reloadData()
            }
        }
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
        if self.powerLevel < kAdminPermission {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        self.chooses[indexPath.section] = indexPath.row
        tableView.reloadSections([indexPath.section], with: .automatic)
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
