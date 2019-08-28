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
        let email: String
        let password: String
        
        func toParams() -> Parameters {
            let params: Parameters = ["email": email, "password": password]
            
            return params
        }
    }
    
    struct Response: Codable {
        let authorization: String?
        
        enum CodingKeys: String, CodingKey {
            case authorization
        }
    }
    
    struct ViewModel {
        let isSuccess: Bool
        let token: String
        let error: Error?
    }
}
