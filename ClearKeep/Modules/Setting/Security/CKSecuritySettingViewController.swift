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
    
    @IBOutlet weak var tableView: UITableView!
    
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
    
    // MARK: Private
    
    private let sections: [[CellType]] = [[.exportKeys]]
    
    // Current alert (if any).
    private var currentAlert: UIAlertController?
    
    // The view used to export e2e keys
    private var exportView: MXKEncryptionKeysExportView?
    
    // The document interaction Controller used to export e2e keys
    private var documentInteractionController: UIDocumentInteractionController?
    
    private var keyExportsFile: URL?
    private var keyExportsFileDeletionTimer: Timer?

    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitization()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = "Security"
    }
    
    private func setupInitization() {
        setupTableView()
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

private extension CKSecuritySettingViewController {
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
        keyExportsFile = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("riot-keys.txt")

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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellType = sections[indexPath.section][indexPath.row]
        
        switch cellType {
        case .exportKeys:
            return cellForButton(tableView, indexPath: indexPath)
        }
    }
}

// MARK: - UITableViewDelegate

extension CKSecuritySettingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CKLayoutSize.Table.row44px
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.selectionStyle = .none
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellType = sections[indexPath.section][indexPath.row]
        
        switch cellType {
        case .exportKeys:
            self.exportEncryptionKeys()
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 45
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if sections[section].contains(where: { $0 == .exportKeys }) {
            let label = UILabel.init()
            label.numberOfLines = 0
            label.font = UIFont.systemFont(ofSize: 14)
            label.textColor = UIColor.init(red: 84/255, green: 84/255, blue: 84/255, alpha: 0.7)
            
            label.text = "You should export your key which is useful to decrypt the messages in the next login."
            
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
