//
//  CKSettingsViewController.swift
//  Riot
//
//  Created by Pham Hoa on 3/7/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

final class CKSettingsViewController: MXKViewController {

    // MARK: - Enums
    
    private enum GroupedSettingType {
        case profile
        case notification
        case others
    }
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let tblDatasource: [[GroupedSettingType]] = [[.profile], [.notification], [.others]]
    
    // MARK: - LifeCycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupInitization()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = "Setting"
    }
    
    private func setupInitization() {
        setupTableView()
    }
}

// MARK: - Private Methods

private extension CKSettingsViewController {
    func setupTableView() {
        tableView.register(UINib.init(nibName: "CKSettingsGroupedItemCell", bundle: Bundle.init(for: CKSettingsGroupedItemCell.self)), forCellReuseIdentifier: "CKSettingsGroupedItemCell")
        
        tableView.dataSource = self
        tableView.delegate = self
        
        // style
    }
}

// MARK: - Public Methods

extension CKSettingsViewController {
    
}

// MARK: UITableViewDataSource

extension CKSettingsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return tblDatasource.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tblDatasource[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CKSettingsGroupedItemCell", for: indexPath) as! CKSettingsGroupedItemCell
        
        let cellType = tblDatasource[indexPath.section][indexPath.row]
        switch cellType {
        case .profile:
            cell.titleLabel.text = "Edit Profile"
            cell.iconImageView.image = #imageLiteral(resourceName: "ic_edit_profile_setting")
        case .notification:
            cell.titleLabel.text = "Notification"
            cell.iconImageView.image = #imageLiteral(resourceName: "ic_notification_setting")
        case .others:
            cell.titleLabel.text = "Privacy & Others"
            cell.iconImageView.image = #imageLiteral(resourceName: "ic_others_setting")
        }
        
        return cell
    }
}

// MARK: UITableViewDelegate

extension CKSettingsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let cellType = tblDatasource[indexPath.section][indexPath.row]
        switch cellType {
        case .profile:
            let vc = CKAccountProfileEditViewController.instance()
            vc.importSession(self.mxSessions)
            self.navigationController?.pushViewController(vc, animated: true)
        case .notification:
            let vc = CKNotificationSettingViewController.instance()
            vc.importSession(self.mxSessions)
            self.navigationController?.pushViewController(vc, animated: true)
        case .others:
            let vc = CKOthersSettingViewController.instance()
            vc.importSession(self.mxSessions)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CKLayoutSize.Table.row40px
    }
}
