//
//  CkAuthorizer.swift
//  Riot
//
//  Created by Sinbad Flyce on 12/21/18.
//  Copyright © 2018 matrix.org. All rights reserved.
//

import Foundation
import MatrixKit

public class CkAuthorizer {
    /**
     The matrix REST client used to make matrix API requests.
     */
    private var mxRestClient: MXRestClient!
    
    /**
     Current request in progress.
     */
    private var mxCurrentOperation: MXHTTPOperation!

    /**
     Customized block used to handle unrecognized certificate (nil by default).
     */
    private var onUnrecognizedCertificateCustomBlock: MXHTTPClientOnUnrecognizedCertificate!;
    
    /**
     The current authentication type (MXKAuthenticationTypeLogin by default).
     */
    internal var authType: MXKAuthenticationType = MXKAuthenticationTypeLogin

    /**
     Username
     */
    internal var userName: String

    /**
     Password
     */
    internal var password: String

    /**
     The home server url (nil by default).
     */
    internal var homeServer: String! = nil
    
    /**
     The identity server url (nil by default).
     */
    internal var identityServer: String! = nil

    /**
     The default home server url (nil by default).
     */
    internal var defaultHomeServer: String! = nil
    
    /**
     The default identity server url (nil by default).
     */
    internal var defaultIdentityServer: String! = nil
    
    /**
     The device name used to display it in the user's devices list (nil by default).
     If nil, the device display name field is filled with a default string: "Mobile", "Tablet"...
     */
    internal var deviceDisplayName: String! = nil
    
    /**
     Initilaze
     */
    init(userName: String, password: String, homeServer: String! = nil,
         identityServer: String! = nil, displayName: String! = nil) {
        self.userName = userName
        self.password = password
        self.homeServer = homeServer
        self.identityServer = identityServer
        self.deviceDisplayName = displayName
    }
    
    /**
     Update REST client
    */
    internal func updateRESTClient() {

        if self.homeServer != nil {
            
            if self.mxRestClient != nil && self.mxRestClient.homeserver != self.homeServer {
                return
            }
            
            if let homeServerUrl = URL(string: self.homeServer) {

                self.mxRestClient = MXRestClient(
                    homeServer: homeServerUrl,
                    unrecognizedCertificateHandler: { (certificate) -> Bool in
                        
                        if self.onUnrecognizedCertificateCustomBlock != nil {
                            return self.onUnrecognizedCertificateCustomBlock(certificate)
                        }
                        
                        // CK-TODO
                        let isTrusted: Bool = true
                        return isTrusted
                })
                
                if self.identityServer != nil {
                    self.mxRestClient.identityServer = self.identityServer
                }
            }
        } else {

            if self.mxRestClient != nil {
                self.mxRestClient.close()
                self.mxRestClient = nil
            }
        }
    }
    
    internal func login(withParameters parameters: [String : Any]) {
        
        self.mxCurrentOperation = self.mxRestClient.login(
            parameters: parameters,
            completion: { (jsonResponse: MXResponse<[String : Any]>) in
                
                if let jsonResponseValue = jsonResponse.value, jsonResponse.isSuccess == true {
                    
                    if let credentials = MXCredentials.model(fromJSON: jsonResponseValue) as? MXCredentials {
                        
                        if credentials.userId == nil || credentials.accessToken == nil {
                            self.onFailureDuringAuthRequest(
                                withError: self.error(withMessage: Bundle.mxk_localizedString(forKey: "not_supported_yet")))
                        } else {
                            credentials.homeServer = self.homeServer
                            credentials.allowedCertificate = self.mxRestClient.allowedCertificate
                            self.onSuccessfulLogin(withCredentials: credentials)
                        }
                    }
                } else {
                    
                    if let error = jsonResponse.error, jsonResponse.isFailure == true {
                        self.onFailureDuringAuthRequest(withError: error as NSError)
                    }
                }
        })
    }
    
    internal func register(withParameters parameters: [String : Any]) {
        
        self.mxCurrentOperation = self.mxRestClient.register(
            parameters: parameters,
            completion: { (jsonResponse: MXResponse<[String : Any]>) in
                
                if let jsonResponseValue = jsonResponse.value, jsonResponse.isSuccess == true {
                    
                    if let credentials = MXCredentials.model(fromJSON: jsonResponseValue) as? MXCredentials {

                        if credentials.userId == nil || credentials.accessToken == nil {
                            self.onFailureDuringAuthRequest(
                                withError: self.error(withMessage: Bundle.mxk_localizedString(forKey: "not_supported_yet")))
                        } else {
                            credentials.homeServer = self.homeServer
                            credentials.allowedCertificate = self.mxRestClient.allowedCertificate
                            self.onSuccessfulLogin(withCredentials: credentials)
                        }
                    }
                } else {
                    
                    if let error = jsonResponse.error, jsonResponse.isFailure == true {
                        self.onFailureDuringAuthRequest(withError: error as NSError)
                    }
                }
        })
    }
    
    internal func refreshAuthenticationSession() {

        if self.mxCurrentOperation != nil {
            self.mxCurrentOperation.cancel()
            self.mxCurrentOperation = nil
        }
        
        if self.mxRestClient != nil {
            
            if self.authType == MXKAuthenticationTypeLogin {
                
                mxCurrentOperation = mxRestClient.getLoginSession(
                    completion: { (response: MXResponse<MXAuthenticationSession>) in
                        
                        if response.isSuccess {
                            self.handleAuthentication(withSession: response.value)
                        } else {
                            self.onFailureDuringMXOperation(withError: response.error)
                        }
                })
            } else if self.authType == MXKAuthenticationTypeRegister {
                mxCurrentOperation = mxRestClient.getLoginSession(
                    completion: { (response: MXResponse<MXAuthenticationSession>) in

                        if response.isSuccess {
                            self.handleAuthentication(withSession: response.value)
                        } else {
                            self.onFailureDuringMXOperation(withError: response.error)
                        }
                })
            } else {
                print("[CK] refreshAuthenticationSession is ignored")
            }
        }
    }
    
    internal func checkInUse(forUsername username: String, completion: @escaping (Bool) -> Void) {
        self.mxCurrentOperation = mxRestClient.isUserNameInUse(username, completion: { (isInUsed: Bool) in
            completion(isInUsed)
        })
    }
}

extension CkAuthorizer {
    
    private func error(withMessage message: String) -> Error {
        return NSError(
            domain: MXKAuthErrorDomain,
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: message]) as Error
    }
    
    private func prepareParameters(completion: ([String: Any]) -> Void) {
        
        var parameters: [String: Any]! = nil
        
        if self.authType == MXKAuthenticationTypeLogin {
            
            if MXTools.isEmailAddress(self.userName) {
                parameters = ["type": kMXLoginFlowTypePassword,
                              "identifier": ["type": kMXLoginIdentifierTypeThirdParty,
                                             "medium": kMX3PIDMediumEmail,
                                             "address": self.userName],
                              "password": self.password,
                              "medium": kMX3PIDMediumEmail,
                              "address": self.userName ]
            } else {
                parameters = ["type": kMXLoginFlowTypePassword,
                              "identifier": ["type": kMXLoginIdentifierTypeUser,
                                             "user": self.userName],
                              "password": self.password,
                              "user": self.userName ]
            }
        } else if self.authType == MXKAuthenticationTypeRegister {
            
        }
    }
}

extension CkAuthorizer {

    private func onFailureDuringAuthRequest(withError error: Error) {
        
    }
    
    private func onSuccessfulLogin(withCredentials credentials: MXCredentials) {
        
    }
    
    private func handleAuthentication(withSession session: MXAuthenticationSession?) {
        
    }
    
    private func onFailureDuringMXOperation(withError: Error?) {
        
    }
}
