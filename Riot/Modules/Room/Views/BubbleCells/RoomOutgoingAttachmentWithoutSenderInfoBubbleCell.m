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

#import "RoomOutgoingAttachmentWithoutSenderInfoBubbleCell.h"
#import "RiotDesignValues.h"
#import "RoomBubbleCellData.h"
#import "MXKRoomBubbleTableViewCell+Riot.h"

@implementation RoomOutgoingAttachmentWithoutSenderInfoBubbleCell

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    self.messageTextView.tintColor = kRiotColorGreen;
}

- (void)render:(MXKCellData *)cellData
{
    [super render:cellData];

    [RoomOutgoingAttachmentBubbleCell render:cellData inBubbleCell:self];
}

+ (CGFloat)heightForCellData:(MXKCellData*)cellData withMaximumWidth:(CGFloat)maxWidth
{
    CGFloat rowHeight = [self attachmentBubbleCellHeightForCellData:cellData withMaximumWidth:maxWidth];

    if (rowHeight <= 0)
    {
        rowHeight = [super heightForCellData:cellData withMaximumWidth:maxWidth];
    }

    return rowHeight;
}

@end
