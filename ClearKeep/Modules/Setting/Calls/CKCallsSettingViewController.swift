//
//  CKCallsSettingViewController.swift
//  Riot
//
//  Created by Pham Hoa on 3/8/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

class CKCallsSettingViewController: MXKViewController {

    // MARK: - IBOutlets
    
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Enums
    
    enum CellType {
        case callIntegration
        
        func title() -> String? {
            switch self {
            case .callIntegration:
                return NSLocalizedString("settings_enable_callkit", tableName: "Vector", bundle: Bundle.main, value: "", comment: "")
            }
        }
    }
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let sections: [[CellType]] = [[.callIntegration]]
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitization()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = "Calls"
    }
    
    private func setupInitization() {
        setupTableView()
        bindingTheme()
    }

    private func bindingTheme() {
        // Binding navigation bar color
        themeService.attrsStream.subscribe(onNext: { [weak self] (theme) in
            self?.defaultBarTintColor = themeService.attrs.navBarBgColor
            self?.barTitleColor = themeService.attrs.primaryTextColor
        }).disposed(by: disposeBag)

        themeService.rx
            .bind({ $0.secondBgColor }, to: view.rx.backgroundColor, tableView.rx.backgroundColor)
            .disposed(by: disposeBag)
    }
    
    override func onMatrixSessionStateDidChange(_ notif: Notification?) {
        // Check whether the concerned session is a new one which is not already associated with this view controller.
        if let mxSession = notif?.object as? MXSession {
            if mxSession.state == MXSessionStateInitialised && self.mxSessions.contains(where: { ($0 as? MXSession) == mxSession }) == true {
                // Store this new session
                addMatrixSession(mxSession)
            } else {
                super.onMatrixSessionStateDidChange(notif)
            }
        }
    }
}

// MARK: - Private Methods

private extension CKCallsSettingViewController {
    func setupTableView() {
        tableView.register(UINib.init(nibName: "CKSettingToggleItemTableViewCell", bundle: Bundle.init(for: CKSettingToggleItemTableViewCell.self)), forCellReuseIdentifier: "CKSettingToggleItemTableViewCell")
        
        tableView.dataSource = self
        tableView.delegate = self
        
        // style
        tableView.allowsSelection = false
    }
    
    @objc func toggleCallKit(_ sender: UISwitch!) {
        MXKAppSettings.standard()?.isCallKitEnabled = sender.isOn
    }
}

extension CKCallsSettingViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CKSettingToggleItemTableViewCell", for: indexPath) as! CKSettingToggleItemTableViewCell

        let cellType = sections[indexPath.section][indexPath.row]
        cell.titleLabel.text = cellType.title()
        cell.theme.backgroundColor = themeService.attrStream{ $0.primaryBgColor }
        cell.titleLabel.theme.textColor = themeService.attrStream{ $0.primaryTextColor }

        switch cellType {
        case .callIntegration:
            cell.switchView.isOn = MXKAppSettings.standard()?.isCallKitEnabled ?? false
            cell.switchView.isEnabled = true
            cell.switchView.addTarget(self, action: #selector(toggleCallKit(_:)), for: UIControlEvents.valueChanged)
        }

        return cell
    }
}

extension CKCallsSettingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CKLayoutSize.Table.row44px
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 45
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if sections[section].contains(where: { $0 == .callIntegration }) {
            let label = UILabel.init()
            label.numberOfLines = 0
            label.font = UIFont.systemFont(ofSize: 14)
            label.theme.textColor = themeService.attrStream{ $0.secondTextColor }

            label.text = NSLocalizedString("settings_callkit_info", tableName: "Vector", bundle: Bundle.main, value: "", comment: "")
            
            let headerView = UIView.init()
            headerView.addSubview(label)
            
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                headerView.leadingAnchor.constraint(equalTo: label.leadingAnchor, constant: -15),
                headerView.trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: 15),
                headerView.topAnchor.constraint(equalTo: label.topAnchor, constant: -5),
                headerView.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 8)
                ])
            
            return headerView
        }
        
        return nil
    }
}
