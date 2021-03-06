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

#import "MXKRoomBubbleTableViewCell+Riot.h"
#import "RoomBubbleCellData.h"
#import "RiotDesignValues.h"
#import <objc/runtime.h>
#import "Riot-Swift.h"

#define VECTOR_ROOMBUBBLETABLEVIEWCELL_TIMELABEL_WIDTH 39

#define VECTOR_ROOMBUBBLETABLEVIEWCELL_MARK_X 48
#define VECTOR_ROOMBUBBLETABLEVIEWCELL_MARK_WIDTH 4

NSString *const kMXKRoomBubbleCellRiotEditButtonPressed = @"kMXKRoomBubbleCellRiotEditButtonPressed";
NSString *const kMXKRoomBubbleCellTapOnReceiptsContainer = @"kMXKRoomBubbleCellTapOnReceiptsContainer";

@implementation MXKRoomBubbleTableViewCell (Riot)

- (void)addTimestampLabelForComponent:(NSUInteger)componentIndex
{
    self.bubbleInfoContainer.hidden = NO;
    
    MXKRoomBubbleComponent *component;
    
    NSArray *bubbleComponents = bubbleData.bubbleComponents;
    
    if (componentIndex < bubbleComponents.count)
    {
        component  = bubbleComponents[componentIndex];
    }
    
    if (component && component.date)
    {
        // Check whether this is the first displayed component.
        BOOL isFirstDisplayedComponent = (componentIndex == 0);
        if ([bubbleData isKindOfClass:RoomBubbleCellData.class])
        {
            isFirstDisplayedComponent = (componentIndex == ((RoomBubbleCellData*)bubbleData).oldestComponentIndex);
        }
        
        CGFloat timeLabelPosX = self.bubbleInfoContainer.frame.size.width - VECTOR_ROOMBUBBLETABLEVIEWCELL_TIMELABEL_WIDTH;
        CGFloat timeLabelPosY = isFirstDisplayedComponent ? 0 : component.position.y + self.msgTextViewTopConstraint.constant - self.bubbleInfoContainerTopConstraint.constant;
        UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(timeLabelPosX, timeLabelPosY, VECTOR_ROOMBUBBLETABLEVIEWCELL_TIMELABEL_WIDTH , 18)];
        
        timeLabel.text = [bubbleData.eventFormatter timeStringFromDate:component.date];
        timeLabel.textAlignment = NSTextAlignmentRight;
        timeLabel.textColor = kRiotSecondaryTextColor;
        if ([UIFont respondsToSelector:@selector(systemFontOfSize:weight:)])
        {
             timeLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightLight];
        }
        else
        {
             timeLabel.font = [UIFont systemFontOfSize:12];
        }
        timeLabel.adjustsFontSizeToFitWidth = YES;

        timeLabel.tag = componentIndex;
        
        [timeLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        timeLabel.accessibilityIdentifier = @"timestampLabel";
        [self.bubbleInfoContainer addSubview:timeLabel];
        
        // Define timeLabel constraints (to handle auto-layout in case of screen rotation)
        NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:timeLabel
                                                                           attribute:NSLayoutAttributeTrailing
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self.bubbleInfoContainer
                                                                           attribute:NSLayoutAttributeTrailing
                                                                          multiplier:1.0
                                                                            constant:0];
        NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:timeLabel
                                                                         attribute:NSLayoutAttributeTop
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.bubbleInfoContainer
                                                                         attribute:NSLayoutAttributeTop
                                                                        multiplier:1.0
                                                                          constant:timeLabelPosY];
        NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:timeLabel
                                                                           attribute:NSLayoutAttributeWidth
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:nil
                                                                           attribute:NSLayoutAttributeNotAnAttribute
                                                                          multiplier:1.0
                                                                            constant:VECTOR_ROOMBUBBLETABLEVIEWCELL_TIMELABEL_WIDTH];
        NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:timeLabel
                                                                            attribute:NSLayoutAttributeHeight
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:nil
                                                                            attribute:NSLayoutAttributeNotAnAttribute
                                                                           multiplier:1.0
                                                                             constant:18];
        
        // Available on iOS 8 and later
        [NSLayoutConstraint activateConstraints:@[rightConstraint, topConstraint, widthConstraint, heightConstraint]];
        
        // Check whether a vertical whitespace was applied to display correctly the timestamp.
        if (!isFirstDisplayedComponent || bubbleData.shouldHideSenderInformation || bubbleData.shouldHideSenderName)
        {
            // Adjust the position of the potential encryption icon in this case.
            if (self.encryptionStatusContainerView)
            {
                NSArray* subviews = self.encryptionStatusContainerView.subviews;
                for (UIView *view in subviews)
                {
                    // Note: The encryption icon has been tagged with the component index.
                    if (view.tag == componentIndex)
                    {
                        CGRect frame = view.frame;
                        frame.origin.y += 15;
                        view.frame = frame;
                        
                        break;
                    }
                }
            }
        }
    }
}

- (void)selectComponent:(NSUInteger)componentIndex
{
    [self selectComponent:componentIndex showEditButton:NO showTimestamp:YES];
}

- (void)selectComponent:(NSUInteger)componentIndex showEditButton:(BOOL)showEditButton showTimestamp:(BOOL)showTimestamp
{
    if (componentIndex < bubbleData.bubbleComponents.count)
    {
        if (showTimestamp)
        {
            // Add time label
            [self addTimestampLabelForComponent:componentIndex];
        }
        
        // Blur timestamp labels which are not related to the selected component (if any)
        for (UIView* view in self.bubbleInfoContainer.subviews)
        {
            // Note dateTime label tag is equal to the index of the related component.
            if (view.tag != componentIndex)
            {
                view.alpha = 0.2;
            }
        }
        
        // Retrieve the read receipts container related to the selected component (if any)
        // Blur the others
        for (UIView* view in self.tmpSubviews)
        {
            // Note read receipt container tag is equal to the index of the related component.
            if (view.tag != componentIndex)
            {
                view.alpha = 0.2;
            }
        }
        
        if (showEditButton)
        {
            // Add the edit button
            [self addEditButtonForComponent:componentIndex completion:nil];
        }
    }
}

- (void)markComponent:(NSUInteger)componentIndex
{
    NSArray *bubbleComponents = bubbleData.bubbleComponents;
    
    if (componentIndex < bubbleComponents.count)
    {
        MXKRoomBubbleComponent *component = bubbleComponents[componentIndex];

        // Define the marker frame
        CGFloat markPosY = component.position.y + self.msgTextViewTopConstraint.constant;
        
        NSInteger mostRecentComponentIndex = bubbleComponents.count - 1;
        if ([bubbleData isKindOfClass:RoomBubbleCellData.class])
        {
            mostRecentComponentIndex = ((RoomBubbleCellData*)bubbleData).mostRecentComponentIndex;
        }
        
        // Compute the mark height.
        // Use the rest of the cell height by default.
        CGFloat markHeight = self.contentView.frame.size.height - markPosY;
        if (componentIndex != mostRecentComponentIndex)
        {
            // There is another component (with display) after this component in the cell.
            // Stop the marker height to the top of this component.
            for (NSInteger index = componentIndex + 1; index < bubbleComponents.count; index ++)
            {
                MXKRoomBubbleComponent *nextComponent  = bubbleComponents[index];
                
                if (nextComponent.attributedTextMessage)
                {
                    markHeight = nextComponent.position.y - component.position.y;
                    break;
                }
            }
        }

        UIView *markerView = [[UIView alloc] initWithFrame:CGRectMake(VECTOR_ROOMBUBBLETABLEVIEWCELL_MARK_X,
                                                                markPosY,
                                                                VECTOR_ROOMBUBBLETABLEVIEWCELL_MARK_WIDTH,
                                                                markHeight)];
        markerView.backgroundColor = kRiotColorGreen;

        [markerView setTranslatesAutoresizingMaskIntoConstraints:NO];
        markerView.accessibilityIdentifier = @"markerView";
        [self.contentView addSubview:markerView];

        // Define the marker constraints
        NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:markerView
                                                                          attribute:NSLayoutAttributeLeading
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self.contentView
                                                                          attribute:NSLayoutAttributeLeading
                                                                         multiplier:1.0
                                                                           constant:VECTOR_ROOMBUBBLETABLEVIEWCELL_MARK_X];
        NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:markerView
                                                                         attribute:NSLayoutAttributeTop
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.contentView
                                                                         attribute:NSLayoutAttributeTop
                                                                        multiplier:1.0
                                                                          constant:markPosY];
        NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:markerView
                                                                           attribute:NSLayoutAttributeWidth
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:nil
                                                                           attribute:NSLayoutAttributeNotAnAttribute
                                                                          multiplier:1.0
                                                                            constant:VECTOR_ROOMBUBBLETABLEVIEWCELL_MARK_WIDTH];
        NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:markerView
                                                                            attribute:NSLayoutAttributeHeight
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:nil
                                                                            attribute:NSLayoutAttributeNotAnAttribute
                                                                           multiplier:1.0
                                                                             constant:markHeight];

        // Available on iOS 8 and later
        [NSLayoutConstraint activateConstraints:@[leftConstraint, topConstraint, widthConstraint, heightConstraint]];
        
        // Store the created button
        self.markerView = markerView;
    }
}

- (void)addDateLabel:(BOOL)timeOnly
{
    self.bubbleInfoContainer.hidden = NO;
    
    NSDate *date = bubbleData.date;
    if (date)
    {
        UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.bubbleInfoContainer.frame.size.width , 18)];
        
        // ck: change date format
        if (timeOnly) {
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateFormat:@"h:mm a"];
            NSString *timeSent = [dateFormat stringFromDate:date];
            timeLabel.text = timeSent;
        } else {
             timeLabel.text = [bubbleData.eventFormatter dateStringFromDate:date withTime:YES];
        }
        
        timeLabel.textAlignment = NSTextAlignmentRight;
        timeLabel.textColor = kRiotSecondaryTextColor;
        if ([UIFont respondsToSelector:@selector(systemFontOfSize:weight:)]) {
            timeLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightLight];
        } else {
            timeLabel.font = [UIFont systemFontOfSize:12];
        }
        timeLabel.adjustsFontSizeToFitWidth = NO;
        [timeLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        [timeLabel sizeToFit];
        timeLabel.accessibilityIdentifier = @"dateLabel";
        [self.bubbleInfoContainer addSubview:timeLabel];
        
        // Define timeLabel constraints (to handle auto-layout in case of screen rotation)
        NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:timeLabel
                                                                           attribute:NSLayoutAttributeTrailing
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self.bubbleInfoContainer
                                                                           attribute:NSLayoutAttributeTrailing
                                                                          multiplier:1.0
                                                                            constant:0];
        NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:timeLabel
                                                                         attribute:NSLayoutAttributeTop
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.bubbleInfoContainer
                                                                         attribute:NSLayoutAttributeTop
                                                                        multiplier:1.0
                                                                          constant:0];
        NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:timeLabel
                                                                           attribute:NSLayoutAttributeWidth
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:nil
                                                                           attribute:NSLayoutAttributeWidth
                                                                          multiplier:1.0
                                                                            constant:timeLabel.frame.size.width];
        NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:timeLabel
                                                                            attribute:NSLayoutAttributeHeight
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:nil
                                                                            attribute:NSLayoutAttributeNotAnAttribute
                                                                           multiplier:1.0
                                                                             constant:18];
        NSLayoutConstraint *nameRightConstraint = [NSLayoutConstraint constraintWithItem:self.userNameLabel
                                                                           attribute:NSLayoutAttributeTrailing
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:timeLabel
                                                                           attribute:NSLayoutAttributeLeading
                                                                          multiplier:1.0
                                                                            constant:-10];

        // Available on iOS 8 and later
        [NSLayoutConstraint activateConstraints:@[rightConstraint, topConstraint, widthConstraint, heightConstraint, nameRightConstraint]];
    }
}

- (void)setBlurred:(BOOL)blurred
{
    objc_setAssociatedObject(self, @selector(blurred), @(blurred), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (blurred)
    {
        self.bubbleOverlayContainer.hidden = NO;
        self.bubbleOverlayContainer.backgroundColor = UIColor.blackColor;
        self.bubbleOverlayContainer.alpha = 0.8;
        self.bubbleOverlayContainer.userInteractionEnabled = YES;
        
        // Blur subviews if any
        for (UIView* view in self.bubbleOverlayContainer.subviews)
        {
            view.alpha = 0.2;
        }
        
        // Move this view in front
        [self.contentView bringSubviewToFront:self.bubbleOverlayContainer];
    }
    else
    {
        if (self.bubbleOverlayContainer.subviews.count)
        {
            // Keep this overlay visible, adjust background color
            self.bubbleOverlayContainer.backgroundColor = [UIColor clearColor];
            self.bubbleOverlayContainer.alpha = 1;
            self.bubbleOverlayContainer.userInteractionEnabled = NO;
            
            // Restore subviews display
            for (UIView* view in self.bubbleOverlayContainer.subviews)
            {
                view.alpha = 1;
            }
        }
        else
        {
            self.bubbleOverlayContainer.hidden = YES;
        }
    }
}

- (BOOL)blurred
{
    NSNumber *associatedBlurred = objc_getAssociatedObject(self, @selector(blurred));
    if (associatedBlurred)
    {
        return [associatedBlurred boolValue];
    }
    return NO;
}

- (void)setEditButton:(UIButton *)editButton
{
    objc_setAssociatedObject(self, @selector(editButton), editButton, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIButton*)editButton
{
    return objc_getAssociatedObject(self, @selector(editButton));
}

- (void)setMarkerView:(UIView *)markerView
{
    objc_setAssociatedObject(self, @selector(markerView), markerView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(UIView *)markerView
{
    return objc_getAssociatedObject(self, @selector(markerView));
}

- (void)updateEventFormatter
{
    MXSession* session = [[AppDelegate theDelegate].mxSessions objectAtIndex:0];
    if (session) {
        // Set a new event formatter
        // TODO: We should use the same EventFormatter instance for all the rooms of a mxSession.
        self.bubbleData.eventFormatter = [[EventFormatter alloc] initWithMatrixSession:session];
        self.bubbleData.eventFormatter.treatMatrixUserIdAsLink = YES;
        self.bubbleData.eventFormatter.treatMatrixRoomIdAsLink = YES;
        self.bubbleData.eventFormatter.treatMatrixRoomAliasAsLink = YES;
        self.bubbleData.eventFormatter.treatMatrixGroupIdAsLink = YES;
    }
}

#pragma mark - User actions

- (IBAction)onEditButtonPressed:(id)sender
{
    if (self.delegate)
    {
        MXEvent *selectedEvent = nil;
        
        // Note edit button tag is equal to the index of the related component.
        NSInteger index = ((UIView*)sender).tag;
        NSArray *bubbleComponents = bubbleData.bubbleComponents;
        
        if (index < bubbleComponents.count)
        {
            MXKRoomBubbleComponent *component = bubbleComponents[index];
            selectedEvent = component.event;
        }
        
        if (selectedEvent)
        {
            [self.delegate cell:self didRecognizeAction:kMXKRoomBubbleCellRiotEditButtonPressed userInfo:@{kMXKRoomBubbleCellEventKey:selectedEvent}];
        }
    }
}

- (IBAction)onReceiptContainerTap:(UITapGestureRecognizer *)sender
{
    if (self.delegate)
    {
        [self.delegate cell:self didRecognizeAction:kMXKRoomBubbleCellTapOnReceiptsContainer userInfo:@{kMXKRoomBubbleCellReceiptsContainerKey : sender.view}];
    }
}

#pragma mark - Internals

- (void)addEditButtonForComponent:(NSUInteger)componentIndex completion:(void (^ __nullable)(BOOL finished))completion
{
    MXKRoomBubbleComponent *component  = bubbleData.bubbleComponents[componentIndex];
    
    // Check whether this is the first displayed component.
    BOOL isFirstDisplayedComponent = (componentIndex == 0);
    if ([bubbleData isKindOfClass:RoomBubbleCellData.class])
    {
        isFirstDisplayedComponent = (componentIndex == ((RoomBubbleCellData*)bubbleData).oldestComponentIndex);
    }
    
    // Define 'Edit' button frame
    UIImage *editIcon = [UIImage imageNamed:@"edit_icon"];
    CGFloat editBtnPosX = self.bubbleInfoContainer.frame.size.width - VECTOR_ROOMBUBBLETABLEVIEWCELL_TIMELABEL_WIDTH - 22 - editIcon.size.width / 2;
    CGFloat editBtnPosY = isFirstDisplayedComponent ? -13 : component.position.y + self.msgTextViewTopConstraint.constant - self.bubbleInfoContainerTopConstraint.constant - 13;
    UIButton *editButton = [[UIButton alloc] initWithFrame:CGRectMake(editBtnPosX, editBtnPosY, 44, 44)];
    
    [editButton setImage:editIcon forState:UIControlStateNormal];
    [editButton setImage:editIcon forState:UIControlStateSelected];
    
    editButton.tag = componentIndex;
    [editButton addTarget:self action:@selector(onEditButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [editButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    editButton.accessibilityIdentifier = @"editButton";
    [self.bubbleInfoContainer addSubview:editButton];
    self.bubbleInfoContainer.userInteractionEnabled = YES;
    
    // Define edit button constraints
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:editButton
                                                                      attribute:NSLayoutAttributeLeading
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.bubbleInfoContainer
                                                                      attribute:NSLayoutAttributeLeading
                                                                     multiplier:1.0
                                                                       constant:editBtnPosX];
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:editButton
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.bubbleInfoContainer
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:editBtnPosY];
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:editButton
                                                                        attribute:NSLayoutAttributeWidth
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:nil
                                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                                       multiplier:1.0
                                                                         constant:44];
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:editButton
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:nil
                                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                                       multiplier:1.0
                                                                         constant:44];
    // Available on iOS 8 and later
    [NSLayoutConstraint activateConstraints:@[leftConstraint, topConstraint, widthConstraint, heightConstraint]];
    
    // Store the created button
    self.editButton = editButton;
}

#pragma mark - Reactions

- (CGRect)componentFrameInTableViewForIndex:(NSInteger)componentIndex
{
    CGRect componentFrameInContentView = [self componentFrameInContentViewForIndex:componentIndex];
    return [self.contentView convertRect:componentFrameInContentView toView:self.superview];
}

- (CGRect)surroundingFrameInTableViewForComponentIndex:(NSInteger)componentIndex
{
    CGRect surroundingFrame;
    
    CGRect componentFrameInContentView = [self componentFrameInContentViewForIndex:componentIndex];
    MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = self;
    MXKRoomBubbleCellData *bubbleCellData = roomBubbleTableViewCell.bubbleData;
    
    NSInteger firstVisibleComponentIndex = NSNotFound;
    NSInteger lastMostRecentComponentIndex = NSNotFound;
    
    if ([bubbleCellData isKindOfClass:[RoomBubbleCellData class]])
    {
        RoomBubbleCellData *roomBubbleCellData = (RoomBubbleCellData*)bubbleCellData;
        firstVisibleComponentIndex = [roomBubbleCellData firstVisibleComponentIndex];
        
        if (roomBubbleCellData.containsLastMessage
            && roomBubbleCellData.mostRecentComponentIndex != NSNotFound
            && roomBubbleCellData.firstVisibleComponentIndex != roomBubbleCellData.mostRecentComponentIndex
            && componentIndex == roomBubbleCellData.mostRecentComponentIndex)
        {
            lastMostRecentComponentIndex = roomBubbleCellData.mostRecentComponentIndex;
        }
    }
    
    // Do not overlap timestamp for last message
    if (lastMostRecentComponentIndex != NSNotFound)
    {
        CGFloat componentBottomY = componentFrameInContentView.origin.y + componentFrameInContentView.size.height;
        
        CGFloat x = 0;
        CGFloat y = componentFrameInContentView.origin.y - RoomBubbleCellLayout.timestampLabelHeight;
        CGFloat width = roomBubbleTableViewCell.contentView.frame.size.width;
        CGFloat height = componentBottomY - y;
        
        surroundingFrame = CGRectMake(x, y, width, height);
    } // Do not overlap user name label for first visible component
    else if (!CGRectEqualToRect(componentFrameInContentView, CGRectNull)
             && firstVisibleComponentIndex != NSNotFound
             && componentIndex <= firstVisibleComponentIndex
             && roomBubbleTableViewCell.userNameLabel
             && roomBubbleTableViewCell.userNameLabel.isHidden == NO)
    {
        CGFloat componentBottomY = componentFrameInContentView.origin.y + componentFrameInContentView.size.height;
        
        CGFloat x = 0;
        CGFloat y = roomBubbleTableViewCell.userNameLabel.frame.origin.y;
        CGFloat width = roomBubbleTableViewCell.contentView.frame.size.width;
        CGFloat height = componentBottomY - y;
        
        surroundingFrame = CGRectMake(x, y, width, height);
    }
    else
    {
        surroundingFrame = componentFrameInContentView;
    }
    
    return [self.contentView convertRect:surroundingFrame toView:self.superview];
}

- (CGRect)componentFrameInContentViewForIndex:(NSInteger)componentIndex
{
    MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = self;
    MXKRoomBubbleCellData *bubbleCellData = roomBubbleTableViewCell.bubbleData;
    MXKRoomBubbleComponent *selectedComponent;
    
    if (bubbleCellData.bubbleComponents.count > componentIndex)
    {
        selectedComponent = bubbleCellData.bubbleComponents[componentIndex];
    }
    
    if (!selectedComponent)
    {
        return CGRectNull;
    }
    
    CGFloat selectedComponenContentViewYOffset = 0;
    CGFloat selectedComponentPositionY = 0;
    CGFloat selectedComponentHeight = 0;
    
    CGRect componentFrame = CGRectNull;
    
    if (roomBubbleTableViewCell.attachmentView)
    {
        CGRect attachamentViewFrame = roomBubbleTableViewCell.attachmentView.frame;
        
        selectedComponenContentViewYOffset = attachamentViewFrame.origin.y;
        selectedComponentHeight = attachamentViewFrame.size.height;
    }
    else if (roomBubbleTableViewCell.messageTextView)
    {
        CGFloat textMessageHeight = 0;
        
        if ([bubbleCellData isKindOfClass:[RoomBubbleCellData class]])
        {
            RoomBubbleCellData *roomBubbleCellData = (RoomBubbleCellData*)bubbleCellData;
            
            if (!roomBubbleCellData.attachment && selectedComponent.attributedTextMessage)
            {
                textMessageHeight = [roomBubbleCellData rawTextHeight:selectedComponent.attributedTextMessage];
            }
        }
        
        selectedComponentPositionY = selectedComponent.position.y;
        
        if (textMessageHeight > 0)
        {
            selectedComponentHeight = textMessageHeight;
        }
        else
        {
            selectedComponentHeight = roomBubbleTableViewCell.frame.size.height - selectedComponentPositionY;
        }
        
        selectedComponenContentViewYOffset = roomBubbleTableViewCell.messageTextView.frame.origin.y;
    }
    
    if (roomBubbleTableViewCell.attachmentView || roomBubbleTableViewCell.messageTextView)
    {
        CGFloat x = 0;
        CGFloat y = selectedComponenContentViewYOffset + selectedComponentPositionY;
        CGFloat width = roomBubbleTableViewCell.contentView.frame.size.width;
        
        componentFrame = CGRectMake(x, y, width, selectedComponentHeight);
    }
    else
    {
        componentFrame = roomBubbleTableViewCell.bounds;
    }
    
    return componentFrame;
}

+ (CGFloat)attachmentBubbleCellHeightForCellData:(MXKCellData *)cellData withMaximumWidth:(CGFloat)maxWidth
{
    MXKRoomBubbleTableViewCell* cell = [self cellWithOriginalXib];
    CGFloat rowHeight = 0;
    
    RoomBubbleCellData *bubbleData;
    
    if ([cellData isKindOfClass:[RoomBubbleCellData class]])
    {
        bubbleData = (RoomBubbleCellData*)cellData;
    }
    
    if (bubbleData && cell.attachmentView && bubbleData.isAttachmentWithThumbnail)
    {
        // retrieve the suggested image view height
        rowHeight = bubbleData.contentSize.height;
        
        // Check here the minimum height defined in cell view for text message
        if (cell.attachViewMinHeightConstraint && rowHeight < cell.attachViewMinHeightConstraint.constant)
        {
            rowHeight = cell.attachViewMinHeightConstraint.constant;
        }
        
        // Finalize the row height by adding the vertical constraints.
        
        rowHeight += cell.attachViewTopConstraint.constant;
        
        CGFloat additionalHeight = bubbleData.additionalContentHeight;
        
        if (additionalHeight)
        {
            rowHeight += additionalHeight;
        }
        else
        {
            rowHeight += cell.attachViewBottomConstraint.constant;
        }
    }
    
    return rowHeight;
}


@end
