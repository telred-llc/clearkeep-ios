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
    func getPassphrase(_ model: CKPassphrase.Request) -> Promise<CKPassphrase.Response> {
        // Pseudo code, will be updated
        return request(.get, "/getPassphrase", parameters: model.toParams(), encoding: JSONEncoding.default).responseTask()
    }
    
    // MARK: create passphrase
    @discardableResult
    func generatePassphrase(_ model: CKPassphrase.Request) -> Promise<CKPassphrase.Response> {
        // Pseudo code, will be updated
        return request(.post, "/api/generatePassphrase", parameters: model.toParams(), encoding: JSONEncoding.default).responseTask()
    }
    
    // MARK: create backup key
    @discardableResult
    func generateBackupKey(_ model: CKPassphrase.Request) -> Promise<CKPassphrase.Response> {
        // Pseudo code, will be updated
        return request(.post, "/api/generateBackupKey", parameters: model.toParams(), encoding: JSONEncoding.default).responseTask()
    }
}
