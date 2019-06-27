//
//  CKNotificationSettingViewController.swift
//  Riot
//
//  Created by Pham Hoa on 3/7/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit
import UserNotifications

class CKNotificationSettingViewController: MXKViewController {

    // MARK: - IBOutlets
    
    @IBOutlet weak var tableView: UITableView!

    // MARK: - Enums
    
    enum CellType {
        case allowNotification
        case showDecryptedContent
        case pinMissedNoti
        case pinUnreadMessage
        
        func title() -> String? {
            switch self {
            case .allowNotification:
                return NSLocalizedString("settings_enable_push_notif", tableName: "Vector", bundle: Bundle.main, value: "", comment: "")
            case .showDecryptedContent:
                return NSLocalizedString("settings_show_decrypted_content", tableName: "Vector", bundle: Bundle.main, value: "", comment: "")
            case .pinMissedNoti:
                return NSLocalizedString("settings_pin_rooms_with_missed_notif", tableName: "Vector", bundle: Bundle.main, value: "", comment: "")
            case .pinUnreadMessage:
                return NSLocalizedString("settings_pin_rooms_with_unread", tableName: "Vector", bundle: Bundle.main, value: "", comment: "")
            }
        }
    }
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let sections: [[CellType]] = [[.allowNotification, .showDecryptedContent], [.pinMissedNoti, .pinUnreadMessage]]
    
    // Current alert (if any).
    private var currentAlert: UIAlertController?

    private let disposeBag = DisposeBag()

    // MARK: - LifeCycle
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitization()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = "Notifications"
    }
    
    private func setupInitization() {
        setupNotification()
        setupTableView()
        bindingTheme()
    }

    private func bindingTheme() {
        // Binding navigation bar color
        themeService.attrsStream.subscribe(onNext: { [weak self] (theme) in
            self?.defaultBarTintColor = themeService.attrs.primaryBgColor
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

private extension CKNotificationSettingViewController {
    func setupTableView() {
        tableView.register(UINib.init(nibName: "CKSettingToggleItemTableViewCell", bundle: Bundle.init(for: CKSettingToggleItemTableViewCell.self)), forCellReuseIdentifier: "CKSettingToggleItemTableViewCell")
        
        tableView.dataSource = self
        tableView.delegate = self
        
        // style
        tableView.allowsSelection = false
    }
    
    func setupNotification() {

        // Add observer to handle removed accounts
        NotificationCenter.default.addObserver(forName: NSNotification.Name.mxkAccountManagerDidRemoveAccount, object: nil, queue: OperationQueue.main, using: { notif in

            if (MXKAccountManager.shared().accounts ?? []).count > 0 {
                // Refresh table to remove this account
                self.refreshSettings()
            }

        })

        // Add observer to handle accounts update
        NotificationCenter.default.addObserver(forName: NSNotification.Name.mxkAccountUserInfoDidChange, object: nil, queue: OperationQueue.main, using: { notif in

            self.stopActivityIndicator()

            self.refreshSettings()

        })

        // Add observer to push settings
        NotificationCenter.default.addObserver(forName: NSNotification.Name.mxkAccountPushKitActivityDidChange, object: nil, queue: OperationQueue.main, using: { notif in

            self.stopActivityIndicator()

            self.refreshSettings()
        })

    }
    
    @objc func togglePushNotifications(_ sender: UISwitch) {

        // Check first whether the user allow notification from device settings
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] (settings) in
            if settings.authorizationStatus == .authorized {
                // Notifications are allowed
                
                let accountManager = MXKAccountManager.shared()
                
                if let account = accountManager?.activeAccounts?.first {
                    
                    DispatchQueue.main.async {
                        self?.startActivityIndicator()
                    }
                    
                    if accountManager?.pushDeviceToken != nil {
                        DispatchQueue.main.async {
                            account.enablePushKitNotifications = !account.isPushKitNotificationActive
                        }
                    } else {
                        // Obtain device token when user has just enabled access to notifications from system settings
                        
                        DispatchQueue.main.async {
                            AppDelegate.the().registerForRemoteNotifications(completion: { error in
                                if error != nil {
                                    DispatchQueue.main.async {
                                        self?.stopActivityIndicator()
                                        sender.setOn(false, animated: true)
                                    }
                                } else {
                                    account.enablePushKitNotifications = true
                                }
                            })
                        }
                    }
                }
            }
            else {
                // Either denied or notDetermined
                
                self?.currentAlert?.dismiss(animated: false)

                let appDisplayName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String

                self?.currentAlert = UIAlertController(title: String(format: NSLocalizedString("settings_on_denied_notification", tableName: "Vector", bundle: Bundle.main, value: "", comment: ""), appDisplayName ?? ""), message: nil, preferredStyle: .alert)

                self?.currentAlert?.addAction(UIAlertAction(title: Bundle.mxk_localizedString(forKey: "ok"), style: .default, handler: { action in
                    self?.currentAlert = nil
                }))
                
                if let currentAlert = self?.currentAlert {
                    DispatchQueue.main.async {
                        currentAlert.mxk_setAccessibilityIdentifier("SettingsVCPushNotificationsAlert")
                        self?.present(currentAlert, animated: true)
                    }
                }

                // Keep off the switch
                DispatchQueue.main.async {
                    sender.isOn = false
                }
            }
        }
    }
    
    @objc func togglePinRoomsWithMissedNotif(_ sender: UISwitch!) {
        RiotSettings.shared.pinRoomsWithMissedNotificationsOnHome = sender.isOn
    }

    @objc func togglePinRoomsWithUnread(_ sender: UISwitch!) {
        RiotSettings.shared.pinRoomsWithUnreadMessagesOnHome = sender.isOn
    }

    @objc func toggleShowDecodedContent(_ sender: UISwitch!) {
        RiotSettings.shared.showDecryptedContentInNotifications = sender.isOn;
    }
}

// MARK: - Public Methods

extension CKNotificationSettingViewController {
    func refreshSettings() {
        self.tableView.reloadData()
    }
}

// MARK: UITableViewDataSource

extension CKNotificationSettingViewController: UITableViewDataSource {
    
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

        let account = MXKAccountManager.shared().activeAccounts.first
        switch cellType {
        case .allowNotification:
            cell.switchView.isOn = account?.isPushKitNotificationActive ?? false
            cell.switchView.isEnabled = true
            cell.switchView.addTarget(self, action: #selector(togglePushNotifications(_:)), for: UIControlEvents.valueChanged)
        case .showDecryptedContent:
            cell.switchView.isOn = RiotSettings.shared.showDecryptedContentInNotifications
            cell.switchView.isEnabled = true
            cell.switchView.addTarget(self, action: #selector(toggleShowDecodedContent(_:)), for: UIControlEvents.valueChanged)
        case .pinMissedNoti:
            cell.switchView.isOn = RiotSettings.shared.pinRoomsWithMissedNotificationsOnHome;
            cell.switchView.isEnabled = true
            cell.switchView.addTarget(self, action: #selector(togglePinRoomsWithMissedNotif(_:)), for: UIControlEvents.valueChanged)
        case .pinUnreadMessage:
            cell.switchView.isOn = RiotSettings.shared.pinRoomsWithUnreadMessagesOnHome;
            cell.switchView.isEnabled = true
            cell.switchView.addTarget(self, action: #selector(togglePinRoomsWithUnread(_:)), for: UIControlEvents.valueChanged)
        }

        cell.theme.backgroundColor = themeService.attrStream{ $0.primaryBgColor }
        cell.titleLabel.theme.textColor = themeService.attrStream{ $0.primaryTextColor }

        return cell
    }
}

extension CKNotificationSettingViewController: UITableViewDelegate {
    
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
        if sections[section].contains(where: { $0 == .pinMissedNoti || $0 == .pinUnreadMessage }) {
            let label = UILabel.init()
            label.numberOfLines = 0
            label.font = UIFont.systemFont(ofSize: 14)
            label.theme.textColor = themeService.attrStream{ $0.secondTextColor }
            
            let appDisplayName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
            label.text = String(format: NSLocalizedString("settings_global_settings_info", tableName: "Vector", bundle: Bundle.main, value: "", comment: ""), appDisplayName ?? "")
            
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
