//
//  CKPassphrase.swift
//  Riot
//
//  Created by klinh on 8/28/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Alamofire

struct CKPassphrase {
    struct Request {
        func toParams() -> Parameters {
            let params: Parameters = ["passphrase": CKAppManager.shared.generatedPassphrase() as Any]
            
            return params
        }
    }
    struct Response: Codable {
        let id: String?
        let passphrase: String?

        enum CodingKeys: String, CodingKey {
            case id
            case passphrase
        }
    }

    struct ViewModel {
        let passphrase: Bool
        let token: String
        let error: Error?
    }
}
