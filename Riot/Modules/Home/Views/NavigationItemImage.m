//
//  NavigationItemImage.m
//  Riot
//
//  Created by Sinbad Flyce on 10/2/18.
//  Copyright © 2018 matrix.org. All rights reserved.
//

#import "NavigationItemImage.h"

@implementation NavigationItemImage

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [[self.imgAvatar layer] setCornerRadius:[self.imgAvatar frame].size.width/2];
    [[self.imgStatus layer] setCornerRadius:[self.imgStatus frame].size.width/2];
    [[self.imgStatus layer] setBorderWidth:1];
    [[self.imgStatus layer] setBorderColor:[UIColor whiteColor].CGColor];
}

- (void)setImageWithUrl:(NSString *)urlString previewImage: (UIImage *)previewImage {
    [self.imgAvatar setEnableInMemoryCache:YES];
    [self.imgAvatar setImageURL:urlString withType:nil andImageOrientation:UIImageOrientationUp previewImage:previewImage];
}

- (void)setImage:(UIImage *)image {
    self.imgAvatar.image = image;
}

- (void)setStatus:(BOOL)online {
    if (online) {
        [self.imgStatus setBackgroundColor:[UIColor colorWithRed:75/255. green:219/255. blue:109/255. alpha:1]];
    } else {
        [self.imgStatus setBackgroundColor:[UIColor grayColor]];
    }
}

@end
