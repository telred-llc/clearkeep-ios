//
//  CKSecuritySettingViewController.swift
//  Riot
//
//  Created by Pham Hoa on 3/8/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

class CKSecuritySettingViewController: MXKViewController {

    // MARK: - IBOutlets
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            self.setupTableView()
        }
    }
    
    // MARK: - Enums
    
    enum CellType {
        case exportKeys

        func title() -> String? {
            switch self {
            case .exportKeys:
                return NSLocalizedString("settings_crypto_export", tableName: "Vector", bundle: Bundle.main, value: "", comment: "")
            }
        }
    }
    
    // MARK: - Properties
    var keyBackupSection: SettingsKeyBackupTableViewSection?
    var keyBackupSetupCoordinatorBridgePresenter: KeyBackupSetupCoordinatorBridgePresenter?
    var keyBackupRecoverCoordinatorBridgePresenter: KeyBackupRecoverCoordinatorBridgePresenter?
    
    private let sections: [[CellType]] = [[.exportKeys]]
    
    // Current alert (if any).
    private var currentAlert: UIAlertController?
    
    // The view used to export e2e keys
    private var exportView: MXKEncryptionKeysExportView?
    
    // The document interaction Controller used to export e2e keys
    private var documentInteractionController: UIDocumentInteractionController?
    
    private var keyExportsFile: URL?
    private var keyExportsFileDeletionTimer: Timer?
    private let disposeBag = DisposeBag()

    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.bindingTheme()
        
        if (self.mainSession.crypto.backup != nil) {
            let deviceInfo = self.mainSession.crypto.deviceList.storedDevice(self.mainSession.matrixRestClient.credentials.userId, deviceId: self.mainSession.matrixRestClient.credentials.deviceId)
            if (deviceInfo != nil) {
                self.keyBackupSection = SettingsKeyBackupTableViewSection(withKeyBackup: self.mainSession.crypto.backup, userDevice: deviceInfo!)
                self.keyBackupSection?.delegate = self
            }
        
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = "Security"
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
    
    // MARK: Private

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
    
    private func setupTableView() {
        tableView.register(UINib.init(nibName: "CKSettingToggleItemTableViewCell", bundle: Bundle.init(for: CKSettingToggleItemTableViewCell.self)), forCellReuseIdentifier: "CKSettingToggleItemTableViewCell")
        tableView.register(UINib.init(nibName: "CKSettingButtonCell", bundle: Bundle.init(for: CKSettingButtonCell.self)), forCellReuseIdentifier: "CKSettingButtonCell")
        tableView.register(UINib(nibName: "MXKTableViewCellWithTextView", bundle: Bundle.init(for: MXKTableViewCellWithTextView.self)), forCellReuseIdentifier: "MXKTableViewCellWithTextView") 
        
        tableView.dataSource = self
        tableView.delegate = self
    }
}

// MARK: - Private Methods

private extension CKSecuritySettingViewController {
    
    // Cells
    
    func cellForButton(_ tableView: UITableView, indexPath: IndexPath) -> CKSettingButtonCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CKSettingButtonCell", for: indexPath) as! CKSettingButtonCell
        
        let cellType = sections[indexPath.section][indexPath.row]
        
        cell.titleLabel.textColor = kRiotColorGreen
        cell.titleLabel.text = cellType.title()
        
        return cell
    }
    
    func cellForNormalItems(_ tableView: UITableView, indexPath: IndexPath) -> CKSettingToggleItemTableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CKSettingToggleItemTableViewCell", for: indexPath) as! CKSettingToggleItemTableViewCell
        
        let cellType = sections[indexPath.section][indexPath.row]
        cell.titleLabel.text = cellType.title()
        
        switch cellType {
        default:
            break
        }
        
        return cell
    }
    
    @objc func deleteKeyExportFile() {
        // Cancel the deletion timer if it is still here
        if keyExportsFileDeletionTimer != nil {
            keyExportsFileDeletionTimer?.invalidate()
            keyExportsFileDeletionTimer = nil
        }

        // And delete the file
        if let keyExportsFile = keyExportsFile, FileManager.default.fileExists(atPath: keyExportsFile.path) {
            try? FileManager.default.removeItem(atPath: keyExportsFile.path)
        }
    }

    // Actions
    
    func exportEncryptionKeys() {
        currentAlert?.dismiss(animated: false)

        exportView = MXKEncryptionKeysExportView(matrixSession: mainSession)
        currentAlert = exportView?.alertController

        // Use a temporary file for the export
        keyExportsFile = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("clearkeep-keys.txt")

        // Make sure the file is empty
        deleteKeyExportFile()

        guard let keyExportsFile = keyExportsFile else { return }
        
        // Show the export dialog
        exportView?.show(in: self, toExportKeysToFile: keyExportsFile, onComplete: { [weak self] success in

            if let strongSelf = self {
                strongSelf.currentAlert = nil
                strongSelf.exportView = nil
                
                if success {
                    // Let another app handling this file
                    strongSelf.documentInteractionController = UIDocumentInteractionController(url: keyExportsFile)
                    strongSelf.documentInteractionController?.delegate = self
                    
                    if self?.documentInteractionController?.presentOptionsMenu(from: strongSelf.view.bounds, in: strongSelf.view, animated: true) == true {
                        // We want to delete the temp keys file after it has been processed by the other app.
                        // We use [UIDocumentInteractionControllerDelegate didEndSendingToApplication] for that
                        // but it is not reliable for all cases (see http://stackoverflow.com/a/21867096).
                        // So, arm a timer to auto delete the file after 10mins.
                        strongSelf.keyExportsFileDeletionTimer = Timer.scheduledTimer(timeInterval: 600, target: strongSelf, selector: #selector(strongSelf.deleteKeyExportFile), userInfo: self, repeats: false)
                    } else {
                        strongSelf.documentInteractionController = nil
                        strongSelf.deleteKeyExportFile()
                    }
                }
            }
        })

    } 
}

// MARK: - UITableViewDataSource

extension CKSecuritySettingViewController: UITableViewDataSource {
    
//    func numberOfSections(in tableView: UITableView) -> Int {
//        return sections.count
//    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return sections[section].count
        if self.keyBackupSection != nil {
            return self.keyBackupSection?.numberOfRows() ?? 0
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.keyBackupSection != nil {
            return self.keyBackupSection?.cellForRow(atRow: indexPath.row) ?? UITableViewCell()
        }
        return UITableViewCell()
        
//        let cellType = sections[indexPath.section][indexPath.row]
//        switch cellType {
//        case .exportKeys:
//            return cellForButton(tableView, indexPath: indexPath)
//        }
    }
}

// MARK: - UITableViewDelegate

extension CKSecuritySettingViewController: UITableViewDelegate {
    
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return CKLayoutSize.Table.row44px
//    }
    
//    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        cell.selectionStyle = .none
//    }
//
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let cellType = sections[indexPath.section][indexPath.row]
//
//        switch cellType {
//        case .exportKeys:
//            self.exportEncryptionKeys()
//        }
//    }
//
    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 45
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        if sections[section].contains(where: { $0 == .exportKeys }) {
//            return createHeaderView(title: "\nYou should export your key which is useful to decrypt the messages in the next login.")
//        } 
        
        return createHeaderView(title: CKLocalization.string(byKey: "settings_key_backup"))
    }

    private func createHeaderView(title: String) -> UIView {
        let label = UILabel.init()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 14)
        label.theme.textColor = themeService.attrStream{ $0.primaryTextColor }
        
        label.text = title
        
        let headerView = UIView.init()
        headerView.addSubview(label)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerView.leadingAnchor.constraint(equalTo: label.leadingAnchor, constant: -15),
            headerView.trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: 15),
            headerView.topAnchor.constraint(equalTo: label.topAnchor, constant: -20),
            headerView.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 8)
            ])
        
        return headerView
    }
}

// MARK: - UIDocumentInteractionControllerDelegate

extension CKSecuritySettingViewController: UIDocumentInteractionControllerDelegate {
    func documentInteractionController(_ controller: UIDocumentInteractionController, didEndSendingToApplication application: String?) {
        // If iOS wants to call this method, this is the right time to remove the file
        deleteKeyExportFile()
    }

    func documentInteractionControllerDidDismissOptionsMenu(_ controller: UIDocumentInteractionController) {
        documentInteractionController = nil
    }
}

extension CKSecuritySettingViewController: SettingsKeyBackupTableViewSectionDelegate {
    
    func settingsKeyBackupTableViewSectionDidUpdate(_ settingsKeyBackupTableViewSection: SettingsKeyBackupTableViewSection) {
        self.tableView.beginUpdates()
        self.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        self.tableView.endUpdates()
    }
    
    func settingsKeyBackupTableViewSection(_ settingsKeyBackupTableViewSection: SettingsKeyBackupTableViewSection, textCellForRow: Int) -> MXKTableViewCellWithTextView {
        return textViewCellForTableView(tableView: self.tableView, atIndexPath: IndexPath())
    }
    
    func settingsKeyBackupTableViewSection(_ settingsKeyBackupTableViewSection: SettingsKeyBackupTableViewSection, buttonCellForRow: Int) -> MXKTableViewCellWithButton {
        if let cell = self.tableView.dequeueReusableCell(withIdentifier: MXKTableViewCellWithButton.defaultReuseIdentifier()) as? MXKTableViewCellWithButton {
            cell.mxkButton.titleLabel?.text = nil;
            cell.mxkButton.tintColor = CKColor.Text.tint
            return cell
        }
        return MXKTableViewCellWithButton()
    }
    
    func settingsKeyBackupTableViewSectionShowKeyBackupSetup(_ settingsKeyBackupTableViewSection: SettingsKeyBackupTableViewSection) {
        self.showKeyBackupSetupFromSignOutFlow(showFromSignOutFlow: false)
    }
    
    func settingsKeyBackup(_ settingsKeyBackupTableViewSection: SettingsKeyBackupTableViewSection, showKeyBackupRecover keyBackupVersion: MXKeyBackupVersion) {
        self.showKeyBackupRecover(keyBackupVersion: keyBackupVersion)
    }
    
    func settingsKeyBackup(_ settingsKeyBackupTableViewSection: SettingsKeyBackupTableViewSection, showKeyBackupDeleteConfirm keyBackupVersion: MXKeyBackupVersion) {
        self.currentAlert?.dismiss(animated: false, completion: nil)
        
        self.currentAlert = UIAlertController(title: CKLocalization.string(byKey: "settings_key_backup_delete_confirmation_prompt_title"), message: CKLocalization.string(byKey: "settings_key_backup_delete_confirmation_prompt_msg"), preferredStyle: .alert)
        self.currentAlert?.addAction(UIAlertAction(title: CKLocalization.string(byKey: "cancel"), style: .cancel, handler: { action in
            self.currentAlert = nil
        }))
        self.currentAlert?.addAction(UIAlertAction(title: CKLocalization.string(byKey: "settings_key_backup_button_delete"), style: .default, handler: { action in
            self.currentAlert = nil
            self.keyBackupSection?.delete(keyBackupVersion: keyBackupVersion)
        }))
        self.currentAlert?.mxk_setAccessibilityIdentifier("SettingsVCDeleteKeyBackup")
        self.present(self.currentAlert!, animated: true, completion: nil)
    }
    
    func settingsKeyBackup(_ settingsKeyBackupTableViewSection: SettingsKeyBackupTableViewSection, showActivityIndicator show: Bool) {
        if (show) {
            self.startActivityIndicator()
        } else {
            self.stopActivityIndicator()
        }
    }
    
    func settingsKeyBackup(_ settingsKeyBackupTableViewSection: SettingsKeyBackupTableViewSection, showError error: Error) {
        AppDelegate.the()?.showError(asAlert: error)
    }
    
    private func textViewCellForTableView(tableView: UITableView, atIndexPath indexPath: IndexPath) -> MXKTableViewCellWithTextView {
        if let textViewCell = tableView.dequeueReusableCell(withIdentifier: MXKTableViewCellWithTextView.defaultReuseIdentifier(), for: indexPath) as? MXKTableViewCellWithTextView {
            textViewCell.mxkTextView.textColor = themeService.attrs.primaryTextColor
            textViewCell.mxkTextView.font = UIFont.systemFont(ofSize: 17)
            textViewCell.mxkTextView.backgroundColor = .clear
            textViewCell.mxkTextViewLeadingConstraint.constant = tableView.separatorInset.left
            textViewCell.mxkTextViewTrailingConstraint.constant = tableView.separatorInset.right
            textViewCell.mxkTextView.accessibilityIdentifier = nil
            return textViewCell;
        }
        return MXKTableViewCellWithTextView()
    }
    
    private func showKeyBackupSetupFromSignOutFlow(showFromSignOutFlow: Bool) {
        self.keyBackupSetupCoordinatorBridgePresenter = KeyBackupSetupCoordinatorBridgePresenter(session: self.mainSession)
        self.keyBackupSetupCoordinatorBridgePresenter?.present(from: self, isStartedFromSignOut: showFromSignOutFlow, animated: true)
        self.keyBackupSetupCoordinatorBridgePresenter?.delegate = self
    }
    
    private func showKeyBackupRecover(keyBackupVersion: MXKeyBackupVersion) {
        self.keyBackupRecoverCoordinatorBridgePresenter = KeyBackupRecoverCoordinatorBridgePresenter(session: self.mainSession, keyBackupVersion: keyBackupVersion)
        self.keyBackupRecoverCoordinatorBridgePresenter?.present(from: self, animated: true)
        self.keyBackupRecoverCoordinatorBridgePresenter?.delegate = self
    }
}

extension CKSecuritySettingViewController: KeyBackupSetupCoordinatorBridgePresenterDelegate {
    func keyBackupSetupCoordinatorBridgePresenterDelegateDidCancel(_ keyBackupSetupCoordinatorBridgePresenter: KeyBackupSetupCoordinatorBridgePresenter) {
        if self.keyBackupSetupCoordinatorBridgePresenter != nil {
            self.keyBackupSetupCoordinatorBridgePresenter?.dismiss(animated: true)
            self.keyBackupSetupCoordinatorBridgePresenter = nil
        }
        
    }
    
    func keyBackupSetupCoordinatorBridgePresenterDelegateDidSetupRecoveryKey(_ keyBackupSetupCoordinatorBridgePresenter: KeyBackupSetupCoordinatorBridgePresenter) {
        if self.keyBackupSetupCoordinatorBridgePresenter != nil {
            self.keyBackupSetupCoordinatorBridgePresenter?.dismiss(animated: true)
            self.keyBackupSetupCoordinatorBridgePresenter = nil
        }
    }
}

extension CKSecuritySettingViewController: KeyBackupRecoverCoordinatorBridgePresenterDelegate {
    
    func keyBackupRecoverCoordinatorBridgePresenterDidCancel(_ keyBackupRecoverCoordinatorBridgePresenter: KeyBackupRecoverCoordinatorBridgePresenter) {
        if self.keyBackupRecoverCoordinatorBridgePresenter != nil {
            self.keyBackupRecoverCoordinatorBridgePresenter?.dismiss(animated: true)
            self.keyBackupRecoverCoordinatorBridgePresenter = nil
        }
    }
    
    func keyBackupRecoverCoordinatorBridgePresenterDidRecover(_ keyBackupRecoverCoordinatorBridgePresenter: KeyBackupRecoverCoordinatorBridgePresenter) {
        if self.keyBackupRecoverCoordinatorBridgePresenter != nil {
            self.keyBackupRecoverCoordinatorBridgePresenter?.dismiss(animated: true)
            self.keyBackupRecoverCoordinatorBridgePresenter = nil
        }
    }
}
