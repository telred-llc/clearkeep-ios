//
//  AuthWebViewController.m
//  Riot
//
//  Created by Sinbad Flyce on 6/15/18.
//  Copyright © 2018 matrix.org. All rights reserved.
//

#import "AuthWebViewController.h"

NSString *const kO365login = @"o365/login";
NSString *const kO365auth = @"login.microsoftonline.com";
NSString *const kO365contacts = @"o365/contacts";

@interface AuthWebViewController ()

@property (weak, nonatomic) IBOutlet WKWebView *webView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicatorView;

@end

@implementation AuthWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.webView setNavigationDelegate:self];
    [self loadWebView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)showActivityView {
    [self.indicatorView setHidden:NO];
    [self.indicatorView startAnimating];
}

- (void)hideActivityView {
    [self.indicatorView setHidden:YES];
    [self.indicatorView stopAnimating];
}

- (void)loadWebView {
    NSURL *loginURL = [NSURL URLWithString:@"https://study.sinbadflyce.com:15050"];
    loginURL = [loginURL URLByAppendingPathComponent:kO365login];
    
    NSString *homeserverUrlString = [[NSUserDefaults standardUserDefaults] objectForKey:@"homeserverurl"];
    NSURL *homeserverUrl = [NSURL URLWithString:homeserverUrlString];
    NSString *fullLoginUrlString = [NSString stringWithFormat:@"%@?hs=%@", loginURL.absoluteString, homeserverUrl.host];
    
    loginURL = [NSURL URLWithString:fullLoginUrlString];
    
    NSURLRequest *loginRequest = [NSURLRequest requestWithURL:loginURL];
    [self.webView loadRequest:loginRequest];
}

- (void)handleO365Login:(NSData *)data {
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    [self dismissViewControllerAnimated:NO completion:nil];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
       [self.delegate authWebViewController:self didO365LoginWithDictionary:dictionary];
    }];    
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    [self showActivityView];
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    [self hideActivityView];
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if ([webView.URL.absoluteString containsString:kO365contacts]) {
        [webView setHidden:YES];
        [webView evaluateJavaScript:@"document.getElementById(\"json-o365\").innerHTML" completionHandler:^(id json, NSError * _Nullable error) {
            NSString *jsonString = (NSString *)json;
            if (jsonString != nil) {
                NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
                [self handleO365Login:data];
            }
        }];
    }
}

@end
