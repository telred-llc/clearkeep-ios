//
//  NavigationItemImage.h
//  Riot
//
//  Created by Sinbad Flyce on 10/2/18.
//  Copyright © 2018 matrix.org. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MatrixKit/MXKImageView.h>

NS_ASSUME_NONNULL_BEGIN

@interface NavigationItemImage : UIView

@property (weak, nonatomic) IBOutlet MXKImageView *imgAvatar;
@property (weak, nonatomic) IBOutlet UIView *imgStatus;

- (void)setImageWithUrl:(NSString *)urlString previewImage: (UIImage *)previewImage;
- (void)setImage:(UIImage *)image;
- (void)setStatus:(BOOL)online;

@end

NS_ASSUME_NONNULL_END
