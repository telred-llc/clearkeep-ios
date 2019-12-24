//
//  CkAuthorizer.swift
//  Riot
//
//  Created by Sinbad Flyce on 12/21/18.
//  Copyright © 2018 matrix.org. All rights reserved.
//

import Foundation
import MatrixKit

protocol CkAuthorizerDelegate: class {        
    func authorizer(_ authorizer: CkAuthorizer, onSuccessfulAuthCredentials credentials: MXCredentials)
    func authorizer(_ authorizer: CkAuthorizer, onFailureDuringAuthError error: Error)
    func resetPassSuccess()
}

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
     Current Session
    */
    private var currentSession: MXAuthenticationSession! = nil

    /**
     Registration Timer
     */
    private var registrationTimer: Timer! = nil
    
    /**
     Reset password Timer
     */
    private var resetPassTimer: Timer! = nil
    
    /**
     Delegates
    */
    internal let delegates = MulticastDelegate<CkAuthorizerDelegate>()
    
    /**
     The current authentication type (MXKAuthenticationTypeLogin by default).
     */
    internal var authType: MXKAuthenticationType = MXKAuthenticationTypeLogin

    /**
     Username/Email
     */
    internal var userId: String

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
    internal var defaultHomeServer: String? = nil
    
    /**
     The default identity server url (nil by default).
     */
    internal var defaultIdentityServer: String? = nil
    
    /**
     The device name used to display it in the user's devices list (nil by default).
     If nil, the device display name field is filled with a default string: "Mobile", "Tablet"...
     */
    internal var deviceDisplayName: String! = nil
        
    /**
     Initilaze
     */
    init(userId: String, password: String, homeServer: String! = nil,
         identityServer: String! = nil, displayName: String! = nil) {
        self.userId = userId
        self.password = password
        self.homeServer = homeServer
        self.identityServer = identityServer
        self.deviceDisplayName = displayName
        
        // Default values
        self.defaultHomeServer = UserDefaults.standard.object(forKey: "homeserverurl") as? String
        self.defaultIdentityServer = UserDefaults.standard.object(forKey: "identityserverurl") as? String
        
        if let dhs = self.defaultHomeServer, let dis = self.defaultIdentityServer {
            if self.homeServer == nil { self.homeServer = dhs}
            if self.identityServer == nil {self.identityServer = dis}
        }
        
        self.updateRESTClient()
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
        
        self.mxCurrentOperation = self.mxRestClient.login (
            parameters: parameters,
            completion: { (jsonResponse: MXResponse<[String : Any]>) in
                
                if let jsonResponseValue = jsonResponse.value, jsonResponse.isSuccess == true {
                    
                    if let loginResp = MXLoginResponse(fromJSON: jsonResponseValue) {
                        
                        let credentials = MXCredentials(loginResponse: loginResp, andDefaultCredentials: nil)
                        
                        if credentials.userId == nil || credentials.accessToken == nil {
                            self.onFailureDuringAuthRequest(
                                withError: self.error(withMessage: Bundle.mxk_localizedString(forKey: "not_supported_yet")))
                        } else {
                            CKAppManager.shared.setup(with: credentials, password: parameters["password"] as? String)
                            credentials.homeServer = self.homeServer
                            credentials.allowedCertificate = self.mxRestClient.allowedCertificate
                            self.onSuccessfulAuthRequest(withCredentials: credentials)
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
        
        if self.registrationTimer != nil {
            self.registrationTimer.invalidate()
            self.registrationTimer = nil
        }
        
        self.mxCurrentOperation = self.mxRestClient.register(
            parameters: parameters,
            completion: { (jsonResponse: MXResponse<[String : Any]>) in
                if let jsonResponseValue = jsonResponse.value, jsonResponse.isSuccess == true {
                    if let loginResp = MXLoginResponse(fromJSON: jsonResponseValue) {
                        let credentials = MXCredentials(loginResponse: loginResp, andDefaultCredentials: nil)
                        if credentials.userId == nil || credentials.accessToken == nil {
                            self.onFailureDuringAuthRequest(
                                withError: self.error(withMessage: Bundle.mxk_localizedString(forKey: "not_supported_yet")))
                        } else {
                            credentials.homeServer = self.homeServer
                            credentials.allowedCertificate = self.mxRestClient.allowedCertificate
                            CKAppManager.shared.setup(with: credentials, password: parameters["password"] as? String)
                            self.onSuccessfulAuthRequest(withCredentials: credentials)
                        }
                    }
                } else {
                    
                    if let error = jsonResponse.error, jsonResponse.isFailure == true {
                        
                        if let mxError = MXError(nsError: error) {
                            
                            if mxError.errcode == kMXErrCodeStringUnauthorized {
                                self.registrationTimer = Timer.scheduledTimer(
                                    timeInterval: 10,
                                    target: self,
                                    selector: #selector(self.registrationTimerFireMethod(timer:)),
                                    userInfo: parameters,
                                    repeats: false)
                                return
                            }
                        }
                        
                        self.onFailureDuringAuthRequest(withError: error as NSError)
                    }
                }
        })
    }
    
    internal func resetPass(withParameters parameters: [String : Any]) {
        
        if self.resetPassTimer != nil {
            self.resetPassTimer.invalidate()
            self.resetPassTimer = nil
        }
        
        self.mxCurrentOperation = self.mxRestClient.resetPassword(parameters: parameters, completion: { (response) in
            if let error = response.error, response.isFailure == true {
                
                if let mxError = MXError(nsError: error) {
                    
                    if mxError.errcode == kMXErrCodeStringUnauthorized {
                        self.resetPassTimer = Timer.scheduledTimer(
                            timeInterval: 5,
                            target: self,
                            selector: #selector(self.resetPassTimerFireMethod(timer:)),
                            userInfo: parameters,
                            repeats: false)
                        return
                    }
                }
                
                self.onFailureDuringAuthRequest(withError: error as NSError)
            } else if response.isSuccess {
                self.delegates.invoke { (agent: CkAuthorizerDelegate) in
                    agent.resetPassSuccess()
                }
            } else {
                self.onFailureDuringAuthRequest(
                    withError: self.error(withMessage: Bundle.mxk_localizedString(forKey: "not_supported_yet")))
            }
        })
    }
    
    internal func refreshAuthenticationSession(completion: @escaping (MXAuthenticationSession?) -> Void) {

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
                            completion(response.value)
                        } else {
                            self.onFailureDuringMXOperation(withError: response.error)
                        }
                })
            } else if self.authType == MXKAuthenticationTypeRegister {
                mxCurrentOperation = mxRestClient.getLoginSession(
                    completion: { (response: MXResponse<MXAuthenticationSession>) in

                        if response.isSuccess {
                            self.handleAuthentication(withSession: response.value)
                            completion(response.value)
                        } else {
                            self.onFailureDuringMXOperation(withError: response.error)
                        }
                })
            } else if self.authType == MXKAuthenticationTypeForgotPassword{
                mxCurrentOperation = mxRestClient.getLoginSession(
                    completion: { (response: MXResponse<MXAuthenticationSession>) in
                        
                        if response.isSuccess {
                            self.handleAuthentication(withSession: response.value)
                            completion(response.value)
                        } else {
                            self.onFailureDuringMXOperation(withError: response.error)
                        }
                })
            } else {
                print("[CK] refreshAuthenticationSession is ignored")
            }
        }
    }
    
    /// Cancel authentication  
    internal func cancelAuthenticationSession() {
        if self.mxCurrentOperation != nil {
            self.mxCurrentOperation.cancel()
            self.mxCurrentOperation = nil
        }
        
        if self.registrationTimer != nil {
            self.registrationTimer.invalidate()
            self.registrationTimer = nil
        }
    }
    
    internal func checkInUse(forUsername username: String, completion: @escaping (Bool) -> Void) {
        self.mxCurrentOperation = mxRestClient.isUserNameInUse(username, completion: { (isInUsed: Bool) in
            completion(isInUsed)
        })
    }
    
    @objc internal func registrationTimerFireMethod(timer: Timer) {
        if timer == self.registrationTimer && timer.isValid {
            if let parameters = timer.userInfo as? [String: Any] {
                self.register(withParameters: parameters)
            }
        }
    }
    
    @objc internal func resetPassTimerFireMethod(timer: Timer) {
        if timer == self.resetPassTimer && timer.isValid {
            if let parameters = timer.userInfo as? [String: Any] {
                self.resetPass(withParameters: parameters)
            }
        }
    }
}

extension CkAuthorizer {
    
    public func startSigningIn() {
        self.authType = MXKAuthenticationTypeLogin
        self.refreshAuthenticationSession { (_) in
            self.prepareParameters { (parameters: [String : Any], error: Error?) in
                if parameters.keys.count > 0 {
                    self.login(withParameters: parameters)
                } else if let err = error {
                    self.onFailureDuringAuthRequest(withError: err)
                }
            }
        }
    }
    
    public func startSigningUp() {
        self.authType = MXKAuthenticationTypeRegister
        self.refreshAuthenticationSession { (_) in
            self.prepareParameters { (parameters: [String : Any], error: Error?) in
                if parameters.keys.count > 0 {
                    self.register(withParameters: parameters)
                } else if let err = error {
                    self.onFailureDuringAuthRequest(withError: err)
                }
            }
        }
    }
    
    public func startResetPass() {
        self.authType = MXKAuthenticationTypeForgotPassword
        self.refreshAuthenticationSession { (_) in
            self.prepareParameters { (parameters: [String : Any], error: Error?) in
                if parameters.keys.count > 0 {
                    self.resetPass(withParameters: parameters)
                } else if let err = error {
                    self.onFailureDuringAuthRequest(withError: err)
                }
            }
        }
    }
    
    public func update(withUserId userId: String, password: String) {
        self.userId = userId
        self.password = password
    }
}

extension CkAuthorizer {
    
    private func error(withMessage message: String) -> Error {
        return NSError(
            domain: MXKAuthErrorDomain,
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: message]) as Error
    }
    
    private func prepareParameters(completion: @escaping ([String: Any], Error?) -> Void) {
        
        var parameters: [String: Any]! = nil
        
        if self.authType == MXKAuthenticationTypeLogin {
            
            if MXTools.isEmailAddress(self.userId) {

                // parms
                parameters = ["type": kMXLoginFlowTypePassword,
                              "identifier": ["type": kMXLoginIdentifierTypeThirdParty,
                                             "medium": kMX3PIDMediumEmail,
                                             "address": self.userId],
                              "password": self.password,
                              "medium": kMX3PIDMediumEmail,
                              "address": self.userId ]
            } else {
                parameters = ["type": kMXLoginFlowTypePassword,
                              "identifier": ["type": kMXLoginIdentifierTypeUser,
                                             "user": self.userId],
                              "password": self.password,
                              "user": self.userId ]
            }
            
            completion(parameters, nil)

        } else if self.authType == MXKAuthenticationTypeRegister {
            if MXTools.isEmailAddress(self.userId) {
                
                if let submittedEmail = MXK3PID(medium: kMX3PIDMediumEmail, andAddress: self.userId) {
                    
                    let nextLink = self.generateNextLink(withClientSecret: submittedEmail.clientSecret)
                    
                    submittedEmail.requestValidationToken(withMatrixRestClient: mxRestClient, isDuringRegistration: true, nextLink: nextLink, success: {
                        
                        if let identServerURL = NSURL(string: self.identityServer) {

                            // get username from email
                            let strs = self.userId.components(separatedBy: "@")
                            let username = strs.count == 2 ? strs.first! : self.userId

                            parameters = ["auth": ["session": self.currentSession.session,
                                                   "threepid_creds": ["client_secret": submittedEmail.clientSecret,
                                                                      "id_server": identServerURL.host,
                                                                      "sid": submittedEmail.sid],
                                                   "type": kMXLoginFlowTypeEmailIdentity],
                                          "username": username,
                                          "password": self.password,
                                          "bind_email": true,
                                          "bind_msisdn": self.isMSISDNFlowCompleted(),
                                          "initial_device_display_name": self.deviceDisplayName]
                            
                            completion(parameters, nil)

                        }
                    }) { (error) in
                        completion([:], error)
                    }
                }
            } else {
                parameters = ["auth": ["session": self.currentSession.session,
                                       "type": kMXLoginFlowTypeDummy],
                              "username": self.userId,
                              "password": self.password,
                              "bind_email": false,
                              "bind_msisdn": false,
                              "initial_device_display_name": self.deviceDisplayName]
                
                completion(parameters, nil)

            }
        } else if self.authType == MXKAuthenticationTypeForgotPassword {
            if let submittedEmail = MXK3PID(medium: kMX3PIDMediumEmail, andAddress: self.userId) {
                mxRestClient.forgetPassword(forEmail: self.userId, clientSecret: submittedEmail.clientSecret, sendAttempt: 1, success: { (response) in
                    if let identServerURL = NSURL(string: self.identityServer) {
                        if let pid = response {
                            parameters = ["auth": ["type": kMXLoginFlowTypeEmailIdentity,
                                                   "threepid_creds": ["client_secret": submittedEmail.clientSecret,
                                                                      "id_server": identServerURL.host,
                                                                      "sid": pid]],
                                          "new_password": self.password]
                            completion(parameters, nil)
                        }
                    }
                }) { (error) in
                    completion([:], error)
                    print("error \(error.debugDescription)")
                }
            }
        }
    }
}

extension CkAuthorizer {

    private func onFailureDuringAuthRequest(withError error: Error) {
        self.delegates.invoke { (agent: CkAuthorizerDelegate) in
            agent.authorizer(self, onFailureDuringAuthError: error)
        }
    }
    
    private func onSuccessfulAuthRequest(withCredentials credentials: MXCredentials) {
        
        self.mxCurrentOperation = nil
        
        if let accm = MXKAccountManager.shared(), let _ = accm.account(forUserId: credentials.userId) {
        } else {
            let account = MXKAccount(credentials: credentials)
            account?.identityServerURL = self.identityServer
            MXKAccountManager.shared()?.addAccount(account, andOpenSession: true)
        }
        
        self.delegates.invoke { (agent: CkAuthorizerDelegate) in
            agent.authorizer(self, onSuccessfulAuthCredentials: credentials)
        }
    }
    
    private func handleAuthentication(withSession session: MXAuthenticationSession?) {
        self.currentSession = session
    }
    
    private func onFailureDuringMXOperation(withError: Error?) {
        if let error = withError {
            self.delegates.invoke { (agent: CkAuthorizerDelegate) in
                agent.authorizer(self, onFailureDuringAuthError: error)
            }
        }
    }
    
    private func generateNextLink(withClientSecret clientSecret: String) -> String {
        
        let empty = ""
        
        guard let appUrl =  Tools.webAppUrl() else {
            return empty
        }
        
        guard let homeserver = mxRestClient.homeserver else {
            return empty
        }
        
        guard let identifyServer = mxRestClient.identityServer else {
            return empty
        }
        
        guard let sessionString = self.currentSession.session else {
            return empty
        }
        
        let nextLink: String = "\(appUrl)/#/register?client_secret=\(clientSecret)&hs_url=\(homeserver)&is_url=\(identifyServer))&session_id=\(sessionString))"
        return nextLink
    }
    
    private func isMSISDNFlowCompleted() -> Bool {
        if currentSession != nil && currentSession.completed != nil {
            if currentSession.completed.index(of: kMXLoginFlowTypeMSISDN) != NSNotFound {
                return true
            }
        }
        return false
    }
}
