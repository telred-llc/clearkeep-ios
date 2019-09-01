//
//  CKRequest.swift
//  Riot
//
//  Created by klinh on 8/28/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Alamofire
import PromiseKit

extension CKAPIClient {
    // MARK: Get passphrase
    @discardableResult
    func getPassphrase() -> Promise<CKPassphrase.Response> {
        return request(.get, "/api/user/get-passphrase", parameters: nil, encoding: JSONEncoding.default).responseTask()
    }
    
    // MARK: create passphrase
    @discardableResult
    func generatePassphrase() -> Promise<CKPassphrase.Response> {
        // Pseudo code, will be updated
        return request(.post, "/api/user/create-passphrase", parameters: CKPassphrase.Request().toParams(), encoding: JSONEncoding.default).responseTask()
    }
    
    // MARK: create backup key
    @discardableResult
    func generateBackupKey(_ model: CKPassphrase.Request) -> Promise<CKPassphrase.Response> {
        // Pseudo code, will be updated
        return request(.post, "/api/generateBackupKey", parameters: model.toParams(), encoding: JSONEncoding.default).responseTask()
    }
}
