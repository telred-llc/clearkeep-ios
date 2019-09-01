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

    private override init() {
        super.init()
        setup()
    }

    // MARK: Public
    
    deinit {
        self.currentHTTPOperation?.cancel()
    }
    
    // MARK: - Private
    func setup() {
        if let session = AppDelegate.the().mxSessions.first as? MXSession,
            let key = session.crypto.backup {
            self.keyBackup = key
        } else {
            self.keyBackup = nil
        }
    }
    
    func setup(_ key: MXKeyBackup) {
        keyBackup = key
    }
    
    func startBackupProcess() {
        checkPasspharse()
    }

    private func restoreKey() {
        guard let passphrase = self.passphrase,
            let key = self.keyBackup,
            let version = key.keyBackupVersion else {
            return
        }
        
        self.currentHTTPOperation = key.restore(version, withPassword: passphrase, room: nil, session: nil, success: { [weak self] (_, _) in
            guard let sself = self else {
                return
            }
            // Trust on decrypt
            sself.currentHTTPOperation = key.trust(version, trust: true, success: { () in
                }, failure: { error in
                    // TO-DO
                    print("restoreKeyBackupVersion success")
            })
            
            }, failure: { error in
                // TO-DO
                print("restoreKeyBackupVersion failed!")
        })
    }
    
    private func createKey() {
        guard let passphrase = self.passphrase, let key = self.keyBackup else {
            return
        }
        
        key.prepareKeyBackupVersion(withPassword: passphrase, success: { (megolmBackupCreationInfo) in
            self.currentHTTPOperation = key.createKeyBackupVersion(megolmBackupCreationInfo, success: { (_) in
                // TO-DO
                print("createKeyBackupVersion success")
                },failure: { (error) in
                    // TO-DO
                    print("createKeyBackupVersion failed")
            })
        })
    }
}

private extension CKKeyBackupRecoverManager {
    @objc func checkPasspharse() {        
        CKAppManager.shared.apiClient.getPassphrase()
            .done({ [weak self] response in
                if let baseData = response.passphrase {
                    // response data has format: "salt:passphrase" (all as base 64)
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
                        print(error.localizedDescription)
                    })
            }
        }
    }

    func handleEncryptedKeyBackupData(with salt: String, passphrase: String) {
        guard let key = self.keyBackup else {
            return
        }
        if let passData = passphrase.rawBase64Decoded(), let saltData = salt.rawBase64Decoded() {
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
}
