//
//  CKAppVersion.swift
//  Riot
//
//  Created by ReasonLeveing on 12/17/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Alamofire

struct CKAppVersion {
    
    struct Request {
        
        var type: String = "ios"
        
        func toParams() -> Parameters {
            
            let params: Parameters = ["type": type]
            
            return params
        }
        
    }
    
    struct Response: Codable {
        
        var id: Int?
        var type: String?
        var version: String?
        var createdAt: Double?
        
        enum CodingKeys: String, CodingKey {
            case id
            case type
            case version
            case createdAt
        }
    }
}


