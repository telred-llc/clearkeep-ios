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

#import "InviteRecentTableViewCell.h"
#import "AvatarGenerator.h"
#import "MXEvent.h"
#import "RecentCellData.h"
#import "RiotDesignValues.h"

#pragma mark - Constant definitions

NSString *const kInviteRecentTableViewCellPreviewButtonPressed = @"kInviteRecentTableViewCellPreviewButtonPressed";
NSString *const kInviteRecentTableViewCellDeclineButtonPressed = @"kInviteRecentTableViewCellDeclineButtonPressed";

NSString *const kInviteRecentTableViewCellRoomKey = @"kInviteRecentTableViewCellRoomKey";

@interface InviteRecentTableViewCell() {
    __weak IBOutlet NSLayoutConstraint *timeLabelWidth;
}
@end

@implementation InviteRecentTableViewCell

#pragma mark - Class methods

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self.leftButton.layer setCornerRadius:5];
    self.leftButton.clipsToBounds = YES;
    [self.leftButton setTitle:NSLocalizedStringFromTable(@"decline", @"Vector", nil) forState:UIControlStateNormal];
    [self.leftButton setTitle:NSLocalizedStringFromTable(@"decline", @"Vector", nil) forState:UIControlStateHighlighted];
    [self.leftButton addTarget:self action:@selector(onDeclinePressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.rightButton.layer setCornerRadius:5];
    self.rightButton.clipsToBounds = YES;
    [self.rightButton setTitle:NSLocalizedStringFromTable(@"preview", @"Vector", nil) forState:UIControlStateNormal];
    [self.rightButton setTitle:NSLocalizedStringFromTable(@"preview", @"Vector", nil) forState:UIControlStateHighlighted];
    [self.rightButton addTarget:self action:@selector(onPreviewPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.noticeBadgeView.layer setCornerRadius:10];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
}

- (void)onDeclinePressed:(id)sender
{
    if (self.delegate)
    {
        MXRoom *room = roomCellData.roomSummary.room;
        
        if (room)
        {
            [self.delegate cell:self didRecognizeAction:kInviteRecentTableViewCellDeclineButtonPressed userInfo:@{kInviteRecentTableViewCellRoomKey:room}];
        }
    }
}

- (void)onPreviewPressed:(id)sender
{
    if (self.delegate)
    {
        MXRoom *room = roomCellData.roomSummary.room;
        
        if (room)
        {
            [self.delegate cell:self didRecognizeAction:kInviteRecentTableViewCellPreviewButtonPressed userInfo:@{kInviteRecentTableViewCellRoomKey:room}];
        }
    }
}

- (void)render:(MXKCellData *)cellData {
    [self.rightButton setBackgroundImage:kRiotInviteCellButton forState:UIControlStateNormal];
    [super render:cellData];
    
    // Replace user name with 'you'
    if ([cellData isKindOfClass:[RecentCellData class]]) {
        RecentCellData *recentData = (RecentCellData *)cellData;
        if ((recentData.lastEvent != nil) && (recentData.lastEvent.wireContent != nil)) {
            NSString * typeString = [recentData.lastEvent.wireContent objectForKey:@"membership"];
            NSString * nameString = [recentData.lastEvent.wireContent objectForKey:@"displayname"];
            if ([typeString isEqualToString:@"invite"]) {
                // Extract the attributes
                NSDictionary *attributes = [(NSAttributedString *)self.lastEventDescription.attributedText attributesAtIndex:0 effectiveRange:NULL];

                NSString *replacedNameString = [recentData.lastEventTextMessage stringByReplacingOccurrencesOfString:nameString withString:@"you"];
                self.lastEventDescription.attributedText = [[NSAttributedString alloc] initWithString:replacedNameString attributes:attributes];
            }
        }
    }

    [self.lastEventDate sizeToFit];
    timeLabelWidth.constant = self.lastEventDate.frame.size.width;
    [self.contentView layoutIfNeeded];
}

+ (CGFloat)heightForCellData:(MXKCellData *)cellData withMaximumWidth:(CGFloat)maxWidth
{
    // The height is fixed
    return 115;
}

@end
