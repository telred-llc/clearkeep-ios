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
    /// Get passphrase
    @discardableResult
    func getPassphrase() -> Promise<CKPassphrase.Response> {
        return request(.get, "/api/user/get-passphrase", parameters: nil, encoding: JSONEncoding.default).responseTask()
    }
    
    /// create passphrase
    @discardableResult
    func generatePassphrase() -> Promise<CKPassphrase.Response> {
        return request(.post, "/api/user/create-passphrase", parameters: CKPassphrase.Request().toParams(), encoding: JSONEncoding.default).responseTask()
    }
    
    /// create backup key
    @discardableResult
    func generateBackupKey(_ model: CKPassphrase.Request) -> Promise<CKPassphrase.Response> {
        // Pseudo code, will be updated
        return request(.post, "/api/generateBackupKey", parameters: model.toParams(), encoding: JSONEncoding.default).responseTask()
    }
}



// MARK: Submit Feedback
extension CKAPIClient {
    
    @discardableResult
//    private
    func requestFeedback(_ model: CKFeedback.Request) -> Promise<CKFeedback.Response> {
        
//        request(.post, "/api/feedback/email", parameters: model.toParams(), encoding: JSONEncoding.default).response { (response) in
//
//            if let error = response.error {
//                return
//            }
//
//            guard let data = response.data else {
//                return
//            }
//
//            let jsonDecoder = JSONDecoder()
//
//            do {
//                let responseData = try jsonDecoder.decode(ResponseData<CKFeedback.Response>.self, from: data)
//
//                if let errorCode = responseData.errorCode, let message = responseData.message {
//
//                    print(errorCode, " --- ", message)
//
//
//                }
//
//            } catch {
//                return
//            }
//        }
//
//        return nil
        
        return request(.post, "/api/feedback/email", parameters: model.toParams(), encoding: JSONEncoding.default).responseTask()
        
//        return request(.post, "/api/feedback/email", parameters: model.toParams(), encoding: JSONEncoding.default).responseTask().done { (_) in
//
//        }
        
    }
    
    
//    func submitFeedback(_ model: CKFeedback.Request, completion: @escaping ((CKFeedback.Response?, Error?) -> Void)) {
//
//        firstly {
//            self.requestFeedback(model)
//        }.done {
////            completion(nil)
//        }.catch { (error) in
////            completion(error)
//        }
//    }
}


// MARK: Get current version application
extension CKAPIClient {
    
    @discardableResult
    func getCurrentVersion(_ model: CKAppVersion.Request, showSpinnerHandler: (() -> Void)) -> Promise<CKAppVersion.Response> {
        
        showSpinnerHandler()
        
        return request(.get, "/api/version/get-current-version", parameters: model.toParams(), encoding: URLEncoding.queryString).responseTask()
    }
    
    @discardableResult
    func getCurrentVersiosn(_ model: CKAppVersion.Request, completion: (() -> Void)) -> Promise<CKAppVersion.Response> {
        completion()
        return request(.get, "/api/version/get-current-version", parameters: model.toParams(), encoding: URLEncoding.queryString).responseTask()
    }
}
