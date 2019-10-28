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
    private var isProcessingKeyData: Bool = false
    private var alert: UIAlertController?
    private override init() {
        super.init()
        setup()
    }

    // MARK: Public
    
    deinit {
        self.currentHTTPOperation?.cancel()
        self.isProcessingKeyData = false
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
        self.alert = nil
        self.passphrase = nil
        self.keyBackup = nil
        self.isProcessingKeyData = false
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
        if self.isProcessingKeyData {
            return
        }
        self.isProcessingKeyData = true
        CKAppManager.shared.apiClient.getPassphrase()
            .done({ [weak self] response in
                if let baseData = response.passphrase, baseData.trimmingCharacters(in: .whitespacesAndNewlines).count > 1 {
                    // response data has format: "salt:passphrase" (all as base 64 separate by ":")
                    let dataArray = baseData.components(separatedBy: ":")
                    if dataArray.count > 1 {
                        self?.handleEncryptedKeyBackupData(with: dataArray[0], passphrase: dataArray[1])
                    }
                } else {
                    self?.display(nil, message: "Invalid passphrase data", title: "Data error")
                }
            })
            .catch({ error in
                self.handleError(error)
            })
    }

    func handleError(_ error: Error) {
        if let serviceError = error as? CKServiceError {
            // passphrase not exist
            if serviceError.errorCode == CKServiceError.entityNotFound.errorCode, CKAppManager.shared.isPasswordAvailable() {
                CKAppManager.shared.apiClient.generatePassphrase()
                    .done({ [weak self] response in
                        if let passphrase = response.passphrase, passphrase.trimmingCharacters(in: .whitespacesAndNewlines).count > 1 {
                            let dataArray = passphrase.components(separatedBy: ":")
                            if dataArray.count > 1 {
                                self?.handleEncryptedKeyBackupData(with: dataArray[0], passphrase: dataArray[1])
                            }
                        } else {
                            self?.display(nil, message: "Invalid passphrase", title: "Data error")
                        }
                    })
                    .catch({ error in
                        self.display(error)
                    })
            } else if !CKAppManager.shared.isPasswordAvailable() {
                // Show errror message
                self.display(nil, message: "If you don't remember your passphrase, consider not logging out because your encrypted messages might be lost", title: "Please re-login to create new backup key!")
            } else {
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
            if let hashString = CKAppManager.shared.passphrase,
                let derivedKeyData = CKDeriver.shared.pbkdf2SHA1(password: hashString,
                                                                 salt: saltData,
                                                                 keyByteCount: CKCryptoConfig.keyLength,
                                                                 rounds: CKCryptoConfig.round),
                let passString = CKAES.init(keyData: derivedKeyData)?.decrypt(data: passData) {
                
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
                    if let _ = self.alert {
                        return
                    }

                    if CKAppManager.shared.userPassword == nil {
                        self.alert = UIAlertController(title: "Restore backup key failed!", message: "Please re-login to create new backup key!\nIf you don't remember your passphrase, consider not logging out because your encrypted messages might be lost", preferredStyle: .alert)
                        
                        self.alert?.addAction(UIAlertAction(title: "Cancel", style: .default, handler: {[weak self] (_) in
                            self?.alert = nil
                        }))
                        
                        self.alert?.addAction(UIAlertAction(title: "Sign out", style: .default, handler: {[weak self] (_) in
                            AppDelegate.the().logout(withConfirmation: false, completion: { (finished) in
                                if finished {
                                    // Clear all cached rooms
                                    CKRoomCacheManager.shared.clearAllCachedData()
                                    CKKeyBackupRecoverManager.shared.destroy()
                                }
                            })
                            self?.alert = nil
                        }))

                        self.alert?.show()
                    } else {
                        self.showPassphraseAlert()
                    }
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
                    print("Delete keyBackupVersion success!")
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

    func display(_ error: Error?, message: String? = nil, title: String? = nil) {
        if let _ = self.alert {
            return
        }
        if let err = error, err.localizedDescription.contains("Invalid") {
            alert = UIAlertController(title: "Invalid passphrase", message: "Try again or using new key (Old data will be lost)", preferredStyle: .alert)
            alert?.addAction(UIAlertAction(title: "Try again", style: .default, handler: { [weak self] (_) in
                self?.showPassphraseAlert()
                self?.alert = nil
            }))
            alert?.addAction(UIAlertAction(title: "New key", style: .default, handler: { [weak self] (_) in
                self?.createKey(false)
                self?.alert = nil
            }))

            alert?.show()
        } else if let msg = message {
            alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
            if msg.contains("your encrypted messages might be lost") {
                self.alert?.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] (_) in
                    self?.alert = nil
                }))
                self.alert?.addAction(UIAlertAction(title: "Sign out", style: .default, handler: { [weak self] (_) in
                    AppDelegate.the().logout(withConfirmation: false, completion: { (finished) in
                        if finished {
                            // Clear all cached rooms
                            CKRoomCacheManager.shared.clearAllCachedData()
                            CKKeyBackupRecoverManager.shared.destroy()
                        }
                    })
                    self?.alert = nil
                }))
            } else {
                self.alert?.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (_) in
                }))
            }

            self.alert?.show()
        }
    }

    func showPassphraseAlert() {
        if let _ = self.alert {
            return
        }
        alert = UIAlertController(title: "", message: "Please enter your current passphrase to recover your old messages", preferredStyle: .alert)
        self.alert?.addTextField(configurationHandler: { (textField) in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
            textField.delegate = self
        })

        self.alert?.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] (_) in
            let textField = self?.alert?.textFields![0]
            if let pass = textField?.text {
                self?.restoreKey(from: pass)
            }
            self?.alert = nil
        }))

        self.alert?.actions[0].isEnabled = false
        self.alert?.show()
    }
}

extension CKKeyBackupRecoverManager: UITextFieldDelegate {
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let fullString = textField.text ?? "" + string
        guard let popup = self.alert else {
            return true
        }
        
        // Textfield will become empty
        if (string == "" && range.location == 0 && (range.length >= fullString.count)) {
            popup.actions[0].isEnabled = false
        } else {
            popup.actions[0].isEnabled = true
        }

        return true
    }
}
