/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "RoomTitleView.h"
#import "Riot-Swift.h"
#import "RiotDesignValues.h"

@implementation RoomTitleView

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([RoomTitleView class])
                          bundle:[NSBundle bundleForClass:[RoomTitleView class]]];
}

- (void)dealloc
{
    _roomPreviewData = nil;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    if (_titleMask)
    {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(reportTapGesture:)];
        [tap setNumberOfTouchesRequired:1];
        [tap setNumberOfTapsRequired:1];
        [tap setDelegate:self];
        [self.titleMask addGestureRecognizer:tap];
        self.titleMask.userInteractionEnabled = YES;
    }
    
    if (_roomDetailsMask)
    {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(reportTapGesture:)];
        [tap setNumberOfTouchesRequired:1];
        [tap setNumberOfTapsRequired:1];
        [tap setDelegate:self];
        [self.roomDetailsMask addGestureRecognizer:tap];
        self.roomDetailsMask.userInteractionEnabled = YES;
    }
    
    if (_addParticipantMask)
    {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(reportTapGesture:)];
        [tap setNumberOfTouchesRequired:1];
        [tap setNumberOfTapsRequired:1];
        [tap setDelegate:self];
        [self.addParticipantMask addGestureRecognizer:tap];
        self.addParticipantMask.userInteractionEnabled = YES;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.superview)
    {
        if (@available(iOS 11.0, *))
        {
            // Force the title view layout by adding 2 new constraints on the UINavigationBarContentView instance.
            NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:self
                                                                             attribute:NSLayoutAttributeTop
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:self.superview
                                                                             attribute:NSLayoutAttributeTop
                                                                            multiplier:1.0f
                                                                              constant:0.0f];
            NSLayoutConstraint *centerXConstraint = [NSLayoutConstraint constraintWithItem:self
                                                                                 attribute:NSLayoutAttributeCenterX
                                                                                 relatedBy:NSLayoutRelationEqual
                                                                                    toItem:self.superview
                                                                                 attribute:NSLayoutAttributeCenterX
                                                                                multiplier:1.0f
                                                                                  constant:0.0f];
            
            // CK: Manage number of bar buttons and change layout
            NSLayoutConstraint *width2button = [NSLayoutConstraint constraintWithItem:self
                                                                            attribute:NSLayoutAttributeWidth
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:self.superview
                                                                            attribute:NSLayoutAttributeWidth
                                                                           multiplier:0.6f
                                                                             constant:0.0f];
            
            NSLayoutConstraint *width3button = [NSLayoutConstraint constraintWithItem:self
                                                                               attribute:NSLayoutAttributeWidth
                                                                               relatedBy:NSLayoutRelationEqual
                                                                               toItem:self.superview
                                                                               attribute:NSLayoutAttributeWidth
                                                                              multiplier:0.4f
                                                                                constant:0.0f];
            // CK: Manage number of bar buttons and change layout
            // -- trick width navigationbar follow case 1,2,3 right barbuttonitems
            // -- fix bug ios 11 titleview, right barbuttonitem change size when update subview
            
            if (self.numberBarButtonItem == 2) {
                [NSLayoutConstraint activateConstraints:@[topConstraint, width2button]];
            } else if (self.numberBarButtonItem == 3) {
                [NSLayoutConstraint activateConstraints:@[topConstraint, width3button]];
            } else {
               [NSLayoutConstraint activateConstraints:@[topConstraint, centerXConstraint]];
            }
            
        }
        else
        {
            // Center horizontally the display name into the navigation bar
            CGRect frame = self.superview.frame;
            
            // Look for the navigation bar.
            UINavigationBar *navigationBar;
            UIView *superView = self;
            while (superView.superview)
            {
                if ([superView.superview isKindOfClass:[UINavigationBar class]])
                {
                    navigationBar = (UINavigationBar*)superView.superview;
                    break;
                }
                
                superView = superView.superview;
            }
            
            if (navigationBar)
            {
                CGSize navBarSize = navigationBar.frame.size;
                CGFloat superviewCenterX = frame.origin.x + (frame.size.width / 2);
                
                // Check whether the view is not moving away (see navigation between view controllers).
                if (superviewCenterX < navBarSize.width)
                {
                    // Center the display name
                    self.displayNameCenterXConstraint.constant = (navBarSize.width / 2) - superviewCenterX;
                }
            }  
        }
    }
}

-(void)customizeViewRendering
{
    [super customizeViewRendering];
    
    self.displayNameTextField.textColor = (self.mxRoom.summary.displayname.length ? kRiotPrimaryTextColor : kRiotSecondaryTextColor);
}

- (void)setRoomPreviewData:(RoomPreviewData *)roomPreviewData
{
    _roomPreviewData = roomPreviewData;
    
    [self refreshDisplay];
}

- (void)refreshDisplay
{
    [super refreshDisplay];
    
    NSString *topicName = @""; // CK: binding data topic label
    
    // Consider in priority the preview data (if any)
    if (self.roomPreviewData)
    {
        self.displayNameTextField.text = self.roomPreviewData.roomName;
        topicName = self.roomPreviewData.roomTopic;
    }
    else if (self.mxRoom)
    {
        self.displayNameTextField.text = self.mxRoom.summary.displayname;
        
        // CK: binding data topic label
        if (self.mxRoom.summary.topic.length) {
            topicName = self.mxRoom.summary.topic;
        }
        
        
        if (!self.displayNameTextField.text.length)
        {
            self.displayNameTextField.text = [NSBundle mxk_localizedStringForKey:@"room_displayname_empty_room"];
            self.displayNameTextField.textColor = kRiotSecondaryTextColor;
        }
        else
        {
            self.displayNameTextField.textColor = kRiotPrimaryTextColor;
        }
        
        self.topicLabel.text = topicName; // CK: binding data topic label
    }
}

- (void)destroy
{
    self.tapGestureDelegate = nil;
    
    [super destroy];
}

- (void)reportTapGesture:(UITapGestureRecognizer*)tapGestureRecognizer
{
    if (self.tapGestureDelegate)
    {
        [self.tapGestureDelegate roomTitleView:self recognizeTapGesture:tapGestureRecognizer];
    }
}

@end
