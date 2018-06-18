//
//  AuthWebViewController.h
//  Riot
//
//  Created by Sinbad Flyce on 6/15/18.
//  Copyright © 2018 matrix.org. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@class AuthWebViewController;

@protocol AuthWebViewControllerDelegate <NSObject>
- (void)authWebViewController: (AuthWebViewController* )controller didO365LoginWithDictionary:(NSDictionary *)dictionary;
@end

@interface AuthWebViewController : UIViewController<WKNavigationDelegate>
@property (weak, nonatomic) id<AuthWebViewControllerDelegate> delegate;
@end
