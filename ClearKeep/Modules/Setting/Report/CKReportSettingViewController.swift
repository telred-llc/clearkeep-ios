//
//  CKReportSettingViewController.swift
//  Riot
//
//  Created by Pham Hoa on 3/8/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

class CKReportSettingViewController: MXKViewController {

    // MARK: - IBOutlets
    
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Enums
    
    enum CellType {
        case sendCrashAndData
        case shakeToReport
        case reportBug
        
        func title() -> String? {
            switch self {
            case .sendCrashAndData:
                return NSLocalizedString("settings_send_crash_report", tableName: "Vector", bundle: Bundle.main, value: "", comment: "")
            case .shakeToReport:
                return NSLocalizedString("settings_enable_rageshake", tableName: "Vector", bundle: Bundle.main, value: "", comment: "")
            case .reportBug:
                return NSLocalizedString("settings_report_bug", tableName: "Vector", bundle: Bundle.main, value: "", comment: "")
            }
        }
    }
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let sections: [[CellType]] = [[.sendCrashAndData, .shakeToReport], [.reportBug]]
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitization()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = "Report"
    }
    
    private func setupInitization() {
        setupTableView()
        bindingTheme()
    }

    func bindingTheme() {
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

private extension CKReportSettingViewController {
    func setupTableView() {
        tableView.register(UINib.init(nibName: "CKSettingToggleItemTableViewCell", bundle: Bundle.init(for: CKSettingToggleItemTableViewCell.self)), forCellReuseIdentifier: "CKSettingToggleItemTableViewCell")
        tableView.register(UINib.init(nibName: "CKSettingButtonCell", bundle: Bundle.init(for: CKSettingButtonCell.self)), forCellReuseIdentifier: "CKSettingButtonCell")

        tableView.dataSource = self
        tableView.delegate = self
    }
    
    // Cells
    
    func cellForButton(_ tableView: UITableView, indexPath: IndexPath) -> CKSettingButtonCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CKSettingButtonCell", for: indexPath) as! CKSettingButtonCell
        
        let cellType = sections[indexPath.section][indexPath.row]
        cell.titleLabel.text = cellType.title()
        
        return cell
    }
    
    func cellForNormalItems(_ tableView: UITableView, indexPath: IndexPath) -> CKSettingToggleItemTableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CKSettingToggleItemTableViewCell", for: indexPath) as! CKSettingToggleItemTableViewCell
        
        let cellType = sections[indexPath.section][indexPath.row]
        cell.titleLabel.text = cellType.title()
        cell.titleLabel.theme.textColor = themeService.attrStream{ $0.primaryTextColor }
        cell.theme.backgroundColor = themeService.attrStream{ $0.primaryBgColor }

        switch cellType {
        case .sendCrashAndData:
            cell.switchView.isOn = RiotSettings.shared.enableCrashReport
            cell.switchView.isEnabled = true
            cell.switchView.addTarget(self, action: #selector(toggleSendCrashReport(_:)), for: .touchUpInside)
        case .shakeToReport:
            cell.switchView.isOn = RiotSettings.shared.enableRageShake
            cell.switchView.isEnabled = true
            cell.switchView.addTarget(self, action: #selector(toggleEnableRageShake(_:)), for: .touchUpInside)
        default:
            break
        }
        
        return cell
    }

    // Actions
    
    @objc func toggleSendCrashReport(_ sender: UISwitch!) {
        let enable = RiotSettings.shared.enableCrashReport
        if enable {
            print("[SettingsViewController] disable automatic crash report and analytics sending")

            RiotSettings.shared.enableCrashReport = false

            Analytics.sharedInstance().stop()

            // Remove potential crash file.
            MXLogger.deleteCrashLog()
        } else {
            print("[SettingsViewController] enable automatic crash report and analytics sending")

            RiotSettings.shared.enableCrashReport = true

            Analytics.sharedInstance().start()
        }
    }
    
    @objc func toggleEnableRageShake(_ sender: UISwitch!) {
        RiotSettings.shared.enableRageShake = sender.isOn

        tableView.reloadData()
    }

    @objc func reportBug() {
        let bugReportViewController = BugReportViewController.init()
        bugReportViewController.show(in: self)
    }
}

extension CKReportSettingViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellType = sections[indexPath.section][indexPath.row]
        
        switch cellType {
        case .reportBug:
            return cellForButton(tableView, indexPath: indexPath)
        default:
            return cellForNormalItems(tableView, indexPath: indexPath)
        }
    }
}

extension CKReportSettingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CKLayoutSize.Table.row44px
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.selectionStyle = .none
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellType = sections[indexPath.section][indexPath.row]
        
        switch cellType {
        case .reportBug:
            self.reportBug()
        default:
            break
        }
    }
}
