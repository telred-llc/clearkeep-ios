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
    
    static let develop = CKEnvironment(name: "DEVELOP", serviceURL: "https://ck-server-demo.herokuapp.com")
    static let production = CKEnvironment(name: "PRODUCTION", serviceURL: "https://ck-server-demo.herokuapp.com")

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
    static let round = 500000
}