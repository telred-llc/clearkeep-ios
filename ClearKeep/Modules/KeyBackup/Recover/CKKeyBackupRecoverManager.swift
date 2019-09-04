//
//  CKKeyBackupRecoverManager.swift
//  Riot
//
//  Created by klinh on 8/30/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

@objcMembers
public class CKKeyBackupRecoverManager: NSObject {
    static let shared = CKKeyBackupRecoverManager()

    // MARK: - Properties
    
    // MARK: Private

    private (set) var keyBackup: MXKeyBackup?
    private var passphrase: String?
    private var currentHTTPOperation: MXHTTPOperation?
    private var isShowingAlert: Bool = false

    private override init() {
        super.init()
        setup()
    }

    // MARK: Public
    
    deinit {
        self.currentHTTPOperation?.cancel()
    }

    // MARK: - Private

    /// Set the manager with the default key from user's sessions,,,
    func setup() {
        if let session = AppDelegate.the().mxSessions.first as? MXSession,
            let key = session.crypto.backup {
            self.keyBackup = key
        } else {
            self.keyBackup = nil
        }
    }

    /// Reset properties
    func destroy() {
        self.currentHTTPOperation?.cancel()
        self.isShowingAlert = false
        self.passphrase = nil
        self.keyBackup = nil
    }
    
    /// Set the manager with a backup key
    func setup(_ key: MXKeyBackup) {
        keyBackup = key
    }

    /// Start the process
    func startBackupProcess() {
        checkPasspharse()
    }
}

private extension CKKeyBackupRecoverManager {
    func checkPasspharse() {
        CKAppManager.shared.apiClient.getPassphrase()
            .done({ [weak self] response in
                if let baseData = response.passphrase {
                    // response data has format: "salt:passphrase" (all as base 64 separate by ":")
                    let dataArray = baseData.components(separatedBy: ":")
                    if dataArray.count > 1 {
                        self?.handleEncryptedKeyBackupData(with: dataArray[0], passphrase: dataArray[1])
                    }
                }
            })
            .catch({ error in
                self.handleError(error)
            })
    }

    func handleError(_ error: Error) {
        if let serviceError = error as? CKServiceError {
            // passphrase not exist
            if serviceError.errorCode == CKServiceError.entityNotFound.errorCode {
                CKAppManager.shared.apiClient.generatePassphrase()
                    .done({ [weak self] response in
                        if let passphrase = response.passphrase {
                            let dataArray = passphrase.components(separatedBy: ":")
                            if dataArray.count > 1 {
                                self?.handleEncryptedKeyBackupData(with: dataArray[0], passphrase: dataArray[1])
                            }
                        }
                    })
                    .catch({ error in
                        self.handleError(error)
                    })
            } else {
                // Show errror message
                self.display(error)
            }
        } else {
            // Show errror message
            self.display(error)
        }
    }

    func handleEncryptedKeyBackupData(with salt: String, passphrase: String) {
        guard let key = self.keyBackup else {
            return
        }

        if let passData = String(passphrase.filter{!" \n\t\r\\".contains($0)}).rawBase64Decoded(),
            let saltData = String(salt.filter{!" \n\t\r\\".contains($0)}).rawBase64Decoded() {
            if let passString = CKAES.init(keyData: saltData)?.decrypt(data: passData) {
                self.passphrase = passString
                switch key.state {
                case MXKeyBackupStateNotTrusted, MXKeyBackupStateWrongBackUpVersion:
                    restoreKey()
                case MXKeyBackupStateDisabled:
                    createKey()
                default:
                    break
                }
            }
        }
    }

    func restoreKey() {
        guard let passphrase = self.passphrase,
            let key = self.keyBackup,
            let version = key.keyBackupVersion else {
                return
        }

        self.currentHTTPOperation = key.restore(version, withPassword: passphrase, room: nil, session: nil, success: { [weak self] (_, _) in
            guard let sself = self else {
                return
            }
            print("restoreKeyBackupVersion success!")

            // Trust on decrypt
            sself.currentHTTPOperation = key.trust(version, trust: true, success: { () in
                print("restoreKeyBackupVersion success to trust!")
            }, failure: { error in
                print("restoreKeyBackupVersion failed to trust!")
                sself.display(error)
            })
            }, failure: { error in
                print("restoreKeyBackupVersion failed!")
                if error.localizedDescription.contains("Invalid recovery key") {
                    if self.isShowingAlert {
                        return
                    }

                    if CKAppManager.shared.userPassword == nil {
                        let alert = UIAlertController(title: "Restore backup key failed!", message: "Please sign out, then sign in and enter your passphrase to recover your old messages", preferredStyle: .alert)
                        
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {(_) in
//                            AppDelegate.the().logout(withConfirmation: false) {_ in
//                            }
                        }))

                        alert.show()
                    } else {
                        self.showPassphraseAlert()
                    }

                    self.isShowingAlert = true
                } else {
                    self.display(error)
                }
        })
    }

    func restoreKey(from oldPassphrase: String) {
        guard let key = self.keyBackup, let version = key.keyBackupVersion else {
                return
        }
        
        self.currentHTTPOperation = key.restore(version, withPassword: oldPassphrase, room: nil, session: nil, success: { [weak self] (_, _) in
            guard let sself = self else {
                return
            }
            print("restoreKeyBackupVersion success!")
            
            // Trust on decrypt
            sself.currentHTTPOperation = key.trust(version, trust: true, success: { [weak self] () in
                print("restoreKeyBackupVersion success to trust!")
                guard let sself = self, let versionString = version.version else {
                    return
                }
                
                // Delete the old key
                sself.currentHTTPOperation = key.deleteVersion(versionString, success: {
                    print("Delete eyBackupVersion success!")
                }, failure: { (error) in
                    sself.display(error)
                })
            }, failure: { error in
                print("restoreKeyBackupVersion failed to trust!")
                sself.display(error)
            })
            }, failure: { error in
                print("restoreKeyBackupVersion failed!")
                self.display(error)
        })
    }

    func createKey(_ firstKey: Bool = true) {
        guard let passphrase = self.passphrase, let key = self.keyBackup else {
            return
        }
        
        key.prepareKeyBackupVersion(withPassword: passphrase, success: { (megolmBackupCreationInfo) in
            self.currentHTTPOperation = key.createKeyBackupVersion(megolmBackupCreationInfo, success: { (_) in
                print("createKeyBackupVersion success")
                if firstKey {
                    return
                }
                self.display(nil, message: "Create key success!")
            },failure: { (error) in
                print("createKeyBackupVersion failed")
            })
        })
    }

    func display(_ error: Error?, message: String? = nil) {
        if let err = error, err.localizedDescription.contains("Invalid recovery key") {
            let alert = UIAlertController(title: "Invalid passphrase", message: "Try again or using new key (Old data will be lost)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Try again", style: .default, handler: { (_) in
                self.isShowingAlert = false
                self.showPassphraseAlert()
            }))
            alert.addAction(UIAlertAction(title: "New key", style: .default, handler: { (_) in
                self.createKey(false)
            }))

            alert.show()
        } else if let msg = message {
            let alert = UIAlertController(title: msg, message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
            }))
            
            alert.show()
        }
    }
    
    func showPassphraseAlert() {
        let alert = UIAlertController(title: "", message: "Please enter your current passphrase to recover your old messages", preferredStyle: .alert)
        alert.addTextField(configurationHandler: { (textField) in
            textField.placeholder = "Password"
        })
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0]
            if let pass = textField?.text, pass.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 {
                self.restoreKey(from: pass)
            }
        }))
        self.isShowingAlert = true
        alert.show()
    }
}

