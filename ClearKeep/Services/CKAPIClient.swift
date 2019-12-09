//
//  CKAPIClient.swift
//  Riot
//
//  Created by klinh on 8/28/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit

class CKAPIClient {
    private (set) var baseURLString: String
    
    var accessToken: String?
    var defaultHeaders: [String: String] {
        return [:]
    }
    
    var authenticator: (( _ header: inout HTTPHeaders, _ parameters: inout Parameters) -> Void)?
    
    lazy var sessionManager: SessionManager = {
        let configuration = URLSessionConfiguration.default
        var headers = SessionManager.defaultHTTPHeaders
        configuration.httpAdditionalHeaders = headers
        return SessionManager(configuration: configuration)
    }()
    
    init(baseURLString: String) {
        self.baseURLString = baseURLString
        
        // should enable network activity indicator here
        // to do
    }
    
    // MARK: Private Methods
    private func fullPath(_ path: String) -> String {
        return baseURLString + path
    }
    
    func request (_ method: HTTPMethod,
                  _ path: String,
                  parameters: Parameters? = nil,
                  encoding: ParameterEncoding = JSONEncoding.default,
                  headers: HTTPHeaders? = nil) -> DataRequest {
        let requestURL = URL(string: fullPath(path)) ?? URL(fileURLWithPath: "")
        var requestHeaders = HTTPHeaders()
        var requestParams = Parameters()
        
        for (key, value) in defaultHeaders {
            requestHeaders[key] = value
        }
        
        if let parameters = parameters {
            for (key, value) in parameters {
                requestParams[key] = value
            }
        }
        
        if let headers = headers {
            for (key, value) in headers {
                requestHeaders[key] = value
            }
        }
        
        if let authenticator = authenticator {
            authenticator(&requestHeaders, &requestParams)
        }
        
        let request = sessionManager.request(requestURL, method: method, parameters: requestParams.count > 0 ? requestParams : nil, encoding: encoding, headers: requestHeaders)
        
        // Logging request & response data
        request.responseString { (response: DataResponse<String>) in
            switch response.result {
            case .success(let value):
                if let data = value.data(using: .utf8) {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data, options: [])
                        let jsonData = try JSONSerialization.data(withJSONObject: json, options: [JSONSerialization.WritingOptions.prettyPrinted])
                        let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
                        CKAPIClient.logData("\(path) - Response:", message: jsonString)
                    } catch {
                        print("\(path) - Response - Invalid fomart: \(value)")
                    }
                } else {
                    print("\(path) - Response - Empty: \(value)")
                }
            case .failure(let error):
                print("\(path) - Response - Error: \(error)")
            }
        }
        
        return request.validate(statusCode: 200..<300)
    }
    
    static func logData(_ tag: String, message: String) {
        print("CK------------------\n")
        print(tag)
        print(message)
        print("CK------------------\n")
    }

    /**
     This depends on json response.
     All response should contain "data" key.
     */

    static func responseObjectSerializer<T: Codable>() -> DataResponseSerializer<T> {
        return DataResponseSerializer(serializeResponse: { urlRequest, _, data, error -> Alamofire.Result<T> in
            if let error = error {
                guard let data = data, data.count > 0 else {
                    return .failure(CKServiceError(code: (error as NSError).code, reason: error.localizedDescription))
                }
                let jsonDecoder = JSONDecoder()
                do {
                    let responseData = try jsonDecoder.decode(ResponseData<T>.self, from: data)
                    if let errorCode = responseData.errorCode, let message = responseData.message {
                        return .failure(CKServiceError(code: errorCode, reason: message))
                    }
                    return .failure(CKServiceError.undefined)
                } catch {
                    return .failure(CKServiceError.invalidDataFormat)
                }
            } else {
                guard let data = data else {
                    return .failure(CKServiceError.emptyResponse)
                }
                let jsonDecoder = JSONDecoder()
                do {
                    let responseData = try jsonDecoder.decode(ResponseData<T>.self, from: data)
                    if responseData.errorCode == 0, let data = responseData.data {
                        return .success(data)
                    } else if let errorCode = responseData.errorCode, let message = responseData.message {
                        return .failure(CKServiceError(code: errorCode, reason: message))
                    }
                    return .failure(CKServiceError.undefined)
                } catch {
                    return .failure(CKServiceError.invalidDataFormat)
                }
            }
        })
    }
    
    static func responseArraySerializer<T: Codable>() -> DataResponseSerializer<[T]> {
        return DataResponseSerializer(serializeResponse: { _, _, data, error -> Alamofire.Result<[T]> in
            if let error = error {
                return .failure(CKServiceError(code: (error as NSError).code, reason: error.localizedDescription))
            } else {
                guard let data = data else {
                    // Empty data
                    return .failure(CKServiceError.emptyResponse)
                }
                let jsonDecoder = JSONDecoder()
                do {
                    let responseData = try jsonDecoder.decode(ResponseDataList<T>.self, from: data)
                    if responseData.errorCode == 0, let data = responseData.data {
                        return .success(data)
                    } else if let errorCode = responseData.errorCode, let message = responseData.message {
                        return .failure(CKServiceError(code: errorCode, reason: message))
                    }
                    return .failure(CKServiceError.undefined)
                } catch {
                    return .failure(CKServiceError.invalidDataFormat)
                }
            }
        })
    }
}

extension DataRequest {
    
    @discardableResult
    public func responseTask<T: Codable>(queue: DispatchQueue? = nil) -> Promise<T> {
        return Promise { seal in
            response(queue: queue, responseSerializer: CKAPIClient.responseObjectSerializer()) { (response: DataResponse<T>) in
                switch response.result {
                case .success(let value):
                    seal.fulfill(value)
                case .failure(let error):
                    seal.reject(error)
                }
            }
        }
    }
    
    @discardableResult
    public func responseArrayTask<T: Codable>(queue: DispatchQueue? = nil) -> Promise<[T]> {
        return Promise { seal in
            response(queue: queue, responseSerializer: CKAPIClient.responseArraySerializer()) { (response: DataResponse<[T]>) in
                switch response.result {
                case .success(let value):
                    seal.fulfill(value)
                case .failure(let error):
                    seal.reject(error)
                }
            }
        }
    }
    
    @discardableResult
    func responseStatus(queue: DispatchQueue? = nil) -> Promise<Bool> {
        return Promise { seal in
            responseData(queue: queue) { response in
                switch response.result {
                case .success(let data):
                    do {
                        let responseData = try JSONDecoder().decode(ResponseStatus.self, from: data)
                        if responseData.errorCode == 200 {
                            seal.fulfill(true)
                        } else if let errorCode = responseData.errorCode, let message = responseData.message {
                            return seal.reject(CKServiceError(code: errorCode, reason: message))
                        }
                        return seal.reject(CKServiceError.undefined)
                    } catch {
                        return seal.reject(CKServiceError.invalidDataFormat)
                    }
                case .failure(let error):
                    seal.reject(error)
                }
            }
        }
    }
}

private struct ResponseStatus: Codable {
    var errorCode: Int?
    var message: String?
    
    enum CodingKeys: String, CodingKey {
        case message, errorCode
    }
}

struct ResponseData<T: Codable>: Codable {
    var errorCode: Int?
    var message: String?
    var data: T?
    
    enum CodingKeys: String, CodingKey {
        case message, data, errorCode
    }
}

private struct ResponseDataList<T: Codable>: Codable {
    var errorCode: Int?
    var message: String?
    var data: [T]?
    
    enum CodingKeys: String, CodingKey {
        case message, data, errorCode
    }
}
