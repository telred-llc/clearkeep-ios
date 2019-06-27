//
//  CKRoomSettingsMoreViewController.swift
//  Riot
//
//  Created by Sinbad Flyce on 2/19/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKRoomSettingsMoreViewController: MXKViewController {
    
    // MARK: - OUTLET
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - ENUM
    
    /**
     Section
     */
    private enum Section: Int {
        case security = 0
        case roles = 1
        case advanced = 2
        
        // count number items
        static func count() -> Int {
            return 3
        }
    }
    
    // MARK: - PROPERTY
    
    /**
     Room object
     */
    public var mxRoom: MXRoom!

    private let disposeBag = DisposeBag()

    // MARK: - OVERRIDE
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Settings"
        self.tableView.register(CKRoomSettingsMoreActionCell.nib, forCellReuseIdentifier: CKRoomSettingsMoreActionCell.identifier)
        self.tableView.reloadData()
        self.bindingTheme()
    }
    
    // MARK: - PRIVATE

    func bindingTheme() {
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
     Initilize cell by index paht
     */
    private func cellForMoreAction(_ indexPath: IndexPath) -> CKRoomSettingsMoreActionCell {
        let cell = self.tableView.dequeueReusableCell(
            withIdentifier: CKRoomSettingsMoreActionCell.identifier, for: indexPath) as! CKRoomSettingsMoreActionCell
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    /**
     Title of header at the section
     */
    private func titleForHeader(atSection section: Int) -> String {
        guard let s = Section(rawValue: section) else { return ""}
        
        switch s {
        case .security:
            return "SECURITY & PRIVACY"
        case .roles:
            return "ROLES AND PERMISSIONS"
        case .advanced:
            return "ADVANCED"
        }
    }
    
    /**
     Titile of cell at the section
     */
    private func titleForCell(atSection section: Int) -> String {
        guard let s = Section(rawValue: section) else { return ""}
        
        switch s {
        case .security:
            return "Security & Privacy"
        case .roles:
            return "Roles and Permissions"
        case .advanced:
            return "Advanced"
        }
    }
    
    private func imageForCell(atSection section: Int) -> UIImage? {
        guard let s = Section(rawValue: section) else { return nil}
        
        switch s {
        case .security:
            return UIImage(named: "ic_setting_more_security")
        case .roles:
            return UIImage(named: "ic_setting_more_roles")
        case .advanced:
            return UIImage(named: "ic_setting_more_advanced")
        }
    }
}


// MARK: - UITableViewDelegate

extension CKRoomSettingsMoreViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CKLayoutSize.Table.defaultHeader
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let s = Section(rawValue: indexPath.section) else { return}
        
        switch s {
        case .security:
            let vc = CKRoomSettingsMoreSecurityViewController.instance()
            vc.importSession(self.mxSessions)
            vc.mxRoom = self.mxRoom
            self.navigationController?.pushViewController(vc, animated: true)
        case .roles:
            let vc = CKRoomSettingsMoreRoleViewController.instance()
            vc.importSession(self.mxSessions)
            vc.mxRoom = self.mxRoom
            self.navigationController?.pushViewController(vc, animated: true)
        case .advanced:
            let vc = CKRoomSettingsMoreAdvancedViewController.instance()
            vc.importSession(self.mxSessions)
            vc.mxRoom = self.mxRoom
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CKLayoutSize.Table.row60px
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let view = CKRoomHeaderInSectionView.instance() {
            view.backgroundColor = CKColor.Background.tableView
            view.descriptionLabel.text = self.titleForHeader(atSection: section)

            view.descriptionLabel.theme.textColor = themeService.attrStream{ $0.primaryTextColor }
            view.theme.backgroundColor = themeService.attrStream{ $0.primaryBgColor }

            return view
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
}

// MARK: - UITableViewDataSource
extension CKRoomSettingsMoreViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.cellForMoreAction(indexPath)
        cell.titleLable.text = self.titleForCell(atSection: indexPath.section)
        cell.iconView.image = self.imageForCell(atSection: indexPath.section)?.withRenderingMode(.alwaysTemplate)

        cell.titleLable.theme.textColor = themeService.attrStream{ $0.primaryTextColor }
        cell.theme.backgroundColor = themeService.attrStream{ $0.secondBgColor }
        cell.iconView.theme.tintColor = themeService.attrStream{ $0.primaryTextColor }
        return cell
    }
}
