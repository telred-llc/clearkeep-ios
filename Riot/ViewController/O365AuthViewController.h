//
//  O365AuthViewController.h
//  Riot
//
//  Created by Sinbad Flyce on 6/14/18.
//  Copyright © 2018 matrix.org. All rights reserved.
//

#import <MatrixKit/MatrixKit.h>
#import "AuthWebViewController.h"

@interface O365AuthViewController : MXKAuthenticationViewController<AuthWebViewControllerDelegate, MXKAuthenticationViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;

@property (weak, nonatomic) IBOutlet UINavigationItem *mainNavigationItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *rightBarButtonItem;

@property (weak, nonatomic) IBOutlet UIView *optionsContainer;

@property (weak, nonatomic) IBOutlet UIButton *skipButton;
@property (weak, nonatomic) IBOutlet UIButton *forgotPasswordButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *submitButtonMinLeadingConstraint;

@property (weak, nonatomic) IBOutlet UIView *serverOptionsContainer;
@property (weak, nonatomic) IBOutlet UIButton *customServersTickButton;
@property (weak, nonatomic) IBOutlet UIView *customServersContainer;
@property (weak, nonatomic) IBOutlet UIView *homeServerContainer;
@property (weak, nonatomic) IBOutlet UIView *identityServerContainer;

@property (weak, nonatomic) IBOutlet UIView *homeServerSeparator;
@property (weak, nonatomic) IBOutlet UIView *identityServerSeparator;

@end
