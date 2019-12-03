//
//  CKFeedbackModel.swift
//  Riot
//
//  Created by ReasonLeveing on 11/28/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Alamofire

struct CKFeedback {
    
    struct Request {
        
        var stars: Int
        var content: String
        
        func toParams() -> Parameters {
            
            let params: Parameters = ["content" : content, "stars" : stars]
            
            return params
        }
    }
    
    
    struct Response: Codable {
        var errorCode: Int
        var message: String
        
        enum CodingKeys: String, CodingKey {
            case errorCode
            case message
        }
    }
    
}
