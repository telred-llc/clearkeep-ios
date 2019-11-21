//
//  CKConstant.swift
//  Riot
//
//  Created by klinh on 8/28/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

struct CKEnvironment {
    let name: String
    let serviceURL: String
    
    static let develop = CKEnvironment(name: "DEVELOP", serviceURL: "https://dev.clearkeep.me")
    static let production = CKEnvironment(name: "PRODUCTION", serviceURL: "https://op.clearkeep.me")

    #if DEVELOP
    static var target = develop
    #else
    static var target = production
    #endif
}

struct CKCryptoConfig {
    /// Count of bytes
    static let saltLength = 32
    
    /// Iterations
    static let round = 10000
    
    /// Key's lenghth
    static let keyLength = 32
}

extension Notification.Name {
    static let ckBackUpKeyDidFail = Notification.Name("CKBackUpKeyDidFail")
    static let ckBackUpKeyDidSuccess = Notification.Name("CKBackUpKeyDidSuccess")
}
