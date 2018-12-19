//
//  CkAuthenticationViewController.swift
//  Riot
//
//  Created by Sinbad Flyce on 11/27/18.
//  Copyright © 2018 matrix.org. All rights reserved.
//

import Foundation
import MatrixKit

final public class CkAuthenticationViewController: MXKViewController {
    
    @IBOutlet weak var authenticationScrollView: UIScrollView!
    @IBOutlet weak var welcomeImageView: UIImageView!
    @IBOutlet weak var signupButton: UIButton!
    
    /**
     The matrix REST client used to make matrix API requests.
     */
    private var mxRestClient: MXRestClient!
    
    /**
     Current request in progress.
     */
    private var mxCurrentOperation: MXHTTPOperation!
    
    /**
     The current authentication type (MXKAuthenticationTypeLogin by default).
     */
    internal var authType: MXKAuthenticationType = MXKAuthenticationTypeLogin
    
    /**
     The default home server url (nil by default).
     */
    internal var defaultHomeServerUrl: String! = nil
    
    /**
     The default identity server url (nil by default).
     */
    internal var defaultIdentityServerUrl: String! = nil
    
    /**
     The device name used to display it in the user's devices list (nil by default).
     If nil, the device display name field is filled with a default string: "Mobile", "Tablet"...
     */
    internal var deviceDisplayName: String! = nil
    
    /**
     Force a registration process based on a predefined set of parameters.
     Use this property to pursue a registration from the next_link sent in an email validation email.
     */
    @objc public var externalRegistrationParameters: NSDictionary!
    
    public class func nib() -> UINib {
        return UINib(nibName: "CkAuthenticationViewController", bundle: Bundle(for: CkAuthenticationViewController.classForCoder()))
    }
    
    convenience init() {
        self.init(nibName: "CkAuthenticationViewController", bundle: Bundle(for: CkAuthenticationViewController.classForCoder()))
    }
    
    public override func finalizeInit() {
        super.finalizeInit()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.authenticationScrollView == nil {
            type(of: self).nib().instantiate(withOwner: self, options: nil)
        }
        
        self.welcomeImageView.image = UIImage(named: "logo")
        self.signupButton.layer.borderWidth = 1
        self.signupButton.layer.borderColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    }
    
    @IBAction func onEmailPress() {
    
    }

    @IBAction func onUsernamePress() {
    
    }
}
