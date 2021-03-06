//
//  CKServiceError.swift
//  Riot
//
//  Created by klinh on 8/28/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

public struct CKServiceError: LocalizedError {
    public enum ServiceErrorCode: Int {
        case none = 0
        case undefined, unauthenticated, emptyResponse, invalidDataFormat, timeout
        case notFound = 21
    }
    
    static let undefined = CKServiceError(code: .undefined, reason: NSLocalizedString("undefine", comment: ""))
    static let unauthenticated = CKServiceError(code: .unauthenticated, reason: NSLocalizedString("unauthenticate", comment: ""))
    static let emptyResponse = CKServiceError(code: .emptyResponse, reason: NSLocalizedString("empty response", comment: ""))
    static let invalidDataFormat = CKServiceError(code: .invalidDataFormat, reason: NSLocalizedString("invalid data fomart", comment: ""))
    static let timeout = CKServiceError(code: .timeout, reason: NSLocalizedString("request time out", comment: ""))
    static let entityNotFound = CKServiceError(code: .notFound, reason: NSLocalizedString("entity not found", comment: ""))

    private (set) var errorCode: Int
    private (set) var message: String
    
    init(code: ServiceErrorCode, reason: String) {
        self.errorCode = code.rawValue
        self.message = reason
    }
    
    init(code: Int, reason: String) {
        self.errorCode = code
        self.message = reason
    }
    
    public var errorDescription: String? {
        get {
            return self.message
        }
    }
}

extension CKServiceError {
    public enum BackupProcessError: Int {
        case none = 0
        case createPassphrase
        case getPassphrase
        case createKey
        case restoreKey
    }
}

// ------

enum CKError {
    
    case loadFailImage
    case unexpectedError
    
    case notEnoughMemberInRoom
    case notAdminCallInRoom
    
}


extension CKError: Error {
    
    public var errorDescription: String {
        switch self {
        case .loadFailImage:
            return CKLocalization.string(byKey: "load_fail_image")
        case .unexpectedError:
            return CKLocalization.string(byKey: "unexpected_error")
        case .notEnoughMemberInRoom:
            return CKLocalization.string(byKey: "call_history_not_enough_member_in_room")
        case .notAdminCallInRoom:
            return CKLocalization.string(byKey: "call_history_not_admin_call_in_room")
        }
    }
    
}
