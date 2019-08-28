//
//  CKServiceError.swift
//  Riot
//
//  Created by klinh on 8/28/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

public struct CKServiceError: LocalizedError {
    public enum ServiceErrorCode: String {
        case undefined, unauthenticated, emptyResponse, invalidDataFormat, timeout
        case incorrectEmail = "INCORRECT_EMAIL"
        case incorrectPassword = "INCORRECT_PASSWORD"
        case accountNotExist = "ACCOUNT_NOT_EXIST"
    }
    
    static let undefined = CKServiceError(code: .undefined, reason: NSLocalizedString("undefine", comment: ""))
    static let unauthenticated = CKServiceError(code: .unauthenticated, reason: NSLocalizedString("unauthenticate", comment: ""))
    static let emptyResponse = CKServiceError(code: .emptyResponse, reason: NSLocalizedString("empty response", comment: ""))
    static let invalidDataFormat = CKServiceError(code: .invalidDataFormat, reason: NSLocalizedString("invalid data fomart", comment: ""))
    static let timeout = CKServiceError(code: .timeout, reason: NSLocalizedString("request time out", comment: ""))
    
    private (set) var code: String
    private (set) var reason: String
    
    init(code: ServiceErrorCode, reason: String) {
        self.code = code.rawValue
        self.reason = reason
    }
    
    init(code: String, reason: String) {
        self.code = code
        self.reason = reason
    }
    
    public var errorDescription: String? {
        get {
            return self.reason
        }
    }
}
