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

#import "SegmentedViewController.h"

#import "RiotDesignValues.h"

@interface SegmentedViewController ()
{
    // Tell whether the segmented view is appeared (see viewWillAppear/viewWillDisappear).
    BOOL isViewAppeared;
    
    // list of displayed UIViewControllers
    NSArray* viewControllers;
    
    // The constraints of the displayed viewController
    NSLayoutConstraint *displayedVCTopConstraint;
    NSLayoutConstraint *displayedVCLeftConstraint;
    NSLayoutConstraint *displayedVCWidthConstraint;
    NSLayoutConstraint *displayedVCHeightConstraint;
    
    // list of NSString
    NSArray* sectionTitles;
    
    // the selected marker view
//    UIView* selectedMarkerView;
//    NSLayoutConstraint *leftMarkerViewConstraint;
    
    // Observe kRiotDesignValuesDidChangeThemeNotification to handle user interface theme change.
    id kRiotDesignValuesDidChangeThemeNotificationObserver;
}

@end

@implementation SegmentedViewController

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([SegmentedViewController class])
                          bundle:[NSBundle bundleForClass:[SegmentedViewController class]]];
}

+ (instancetype)segmentedViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass([SegmentedViewController class])
                                          bundle:[NSBundle bundleForClass:[SegmentedViewController class]]];
}

/**
 init the segmentedViewController with a list of UIViewControllers.
 @param titles the section tiles
 @param viewControllers the list of viewControllers to display.
 @param defaultSelected index of the default selected UIViewController in the list.
 */
- (void)initWithTitles:(NSArray*)titles viewControllers:(NSArray*)someViewControllers defaultSelected:(NSUInteger)defaultSelected
{
    viewControllers = someViewControllers;
    sectionTitles = titles;
    _selectedIndex = defaultSelected;
}

- (void)destroy
{
    for (id viewController in viewControllers)
    {
        if ([viewController respondsToSelector:@selector(destroy)])
        {
            [viewController destroy];
        }
    }
    viewControllers = nil;
    sectionTitles = nil;

//    if (selectedMarkerView)
//    {
//        [selectedMarkerView removeFromSuperview];
//        selectedMarkerView = nil;
//    }
    
    if (kRiotDesignValuesDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kRiotDesignValuesDidChangeThemeNotificationObserver];
        kRiotDesignValuesDidChangeThemeNotificationObserver = nil;
    }
    
    [super destroy];
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    if (_selectedIndex != selectedIndex)
    {
        _selectedIndex = selectedIndex;
        [self displaySelectedViewController];
    }
}

- (NSArray<UIViewController *> *)viewControllers
{
    return viewControllers;
}

#pragma mark -

- (void)finalizeInit
{
    [super finalizeInit];
    
    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
    
    self.sectionHeaderTintColor = kRiotColorGreen;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Check whether the view controller has been pushed via storyboard
    if (!self.viewControllerContainer)
    {
        // Instantiate view controller objects
        [[[self class] nib] instantiateWithOwner:self options:nil];
    }
    
    [self createSegmentedViews];
    
    // Observe user interface theme change.
    kRiotDesignValuesDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kRiotDesignValuesDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self userInterfaceThemeDidChange];
        
    }];
    [self userInterfaceThemeDidChange];
}

- (void)userInterfaceThemeDidChange
{
    self.defaultBarTintColor = kRiotSecondaryBgColor;
    self.barTitleColor = kRiotPrimaryTextColor;
    self.activityIndicator.backgroundColor = kRiotOverlayColor;
    
    self.view.backgroundColor = kRiotPrimaryBgColor;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return kRiotDesignStatusBarStyle;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (_selectedViewController)
    {
        // Make iOS invoke child viewWillAppear
        [_selectedViewController beginAppearanceTransition:YES animated:animated];
    }
    
    isViewAppeared = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (_selectedViewController)
    {
        // Make iOS invoke child viewWillDisappear
        [_selectedViewController beginAppearanceTransition:NO animated:animated];
    }
    
    isViewAppeared = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (_selectedViewController)
    {
        // Make iOS invoke child viewDidAppear
        [_selectedViewController endAppearanceTransition];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (_selectedViewController)
    {
        // Make iOS invoke child viewDidDisappear
        [_selectedViewController endAppearanceTransition];
    }
}

- (void)createSegmentedViews
{
    NSUInteger count = viewControllers.count;
    
    for (NSUInteger index = 0; index < count; index++)
    {
        // Handle container view
        [_selectionContainer.layer setCornerRadius:5.0];
        _selectionContainer.clipsToBounds = YES;
        _selectionContainer.layer.masksToBounds = YES;
        
        // create programmatically each label
        UIButton *button = _segmentButtons[index];
        [button setTitle:[sectionTitles objectAtIndex:index] forState:UIControlStateNormal];
        [button setBackgroundColor: [UIColor colorWithRed:240.0/255.0 green:240.0/255.0 blue:240.0/255.0 alpha:1.0]];
        [button setBackgroundImage:[UIImage imageNamed:@"btn_section_highlight"] forState:UIControlStateSelected];
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        button.titleLabel.font = [UIFont fontWithName:@"SFCompactDisplay-Regular" size:15];
        button.titleLabel.textColor = [UIColor colorWithRed:68.0/255.0 green:68.0/255.0 blue:68.0/255.0 alpha:1];
        button.accessibilityIdentifier = [NSString stringWithFormat:@"SegmentedVCSectionLabel%tu", index];
        [button setTitleColor:[UIColor colorWithRed:68.0/255.0 green:68.0/255.0 blue:68.0/255.0 alpha:1.0] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0] forState:UIControlStateSelected];
        
        self.selectionContainer.backgroundColor = [UIColor colorWithRed:240.0/255.0 green:240.0/255.0 blue:240.0/255.0 alpha:1.0];
        UITapGestureRecognizer *labelTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onLabelTouch:)];
        [labelTapGesture setNumberOfTouchesRequired:1];
        [labelTapGesture setNumberOfTapsRequired:1];
        button.userInteractionEnabled = YES;
        [button addGestureRecognizer:labelTapGesture];
            
    }
    
    [self displaySelectedViewController];
}

- (void)displaySelectedViewController
{
    // Sanity check
    NSAssert(_segmentButtons.count, @"[SegmentedViewController] displaySelectedViewController failed - At least one view controller is required");

    if (_selectedViewController)
    {
        NSUInteger index = [viewControllers indexOfObject:_selectedViewController];
        
        if (index != NSNotFound)
        {
            UIButton* button = [_segmentButtons objectAtIndex: index];
            button.titleLabel.font = [UIFont fontWithName:@"SFCompactDisplay-Regular" size:15];
        }
        
        [_selectedViewController willMoveToParentViewController:nil];
        [_selectedViewController.view removeFromSuperview];
        [_selectedViewController removeFromParentViewController];
        
    }
    
    UIButton* button = [_segmentButtons objectAtIndex:_selectedIndex];
    button.titleLabel.font = [UIFont fontWithName:@"SFCompactDisplay-Regular" size:15];//[UIFont boldSystemFontOfSize:17];
    [button setSelected:YES];
    
    // Set the new selected view controller
    _selectedViewController = [viewControllers objectAtIndex:_selectedIndex];

    // Make iOS invoke selectedViewController viewWillAppear when the segmented view is already visible
    if (isViewAppeared)
    {
        [_selectedViewController beginAppearanceTransition:YES animated:YES];
    }

    [self addChildViewController:_selectedViewController];
    
    [_selectedViewController.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.viewControllerContainer addSubview:_selectedViewController.view];
    
    
    displayedVCTopConstraint = [NSLayoutConstraint constraintWithItem:_selectedViewController.view
                                                            attribute:NSLayoutAttributeTop
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:self.viewControllerContainer
                                                            attribute:NSLayoutAttributeTop
                                                           multiplier:1.0f
                                                             constant:0.0f];
    
    displayedVCLeftConstraint = [NSLayoutConstraint constraintWithItem:_selectedViewController.view
                                                             attribute:NSLayoutAttributeLeading
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.viewControllerContainer
                                                             attribute:NSLayoutAttributeLeading
                                                            multiplier:1.0f
                                                              constant:0.0f];
    
    displayedVCWidthConstraint = [NSLayoutConstraint constraintWithItem:_selectedViewController.view
                                                                        attribute:NSLayoutAttributeWidth
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self.viewControllerContainer
                                                                        attribute:NSLayoutAttributeWidth
                                                                       multiplier:1.0
                                                                         constant:0];
    
    displayedVCHeightConstraint = [NSLayoutConstraint constraintWithItem:_selectedViewController.view
                                                              attribute:NSLayoutAttributeHeight
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.viewControllerContainer
                                                              attribute:NSLayoutAttributeHeight
                                                             multiplier:1.0
                                                               constant:0];
    
    [NSLayoutConstraint activateConstraints:@[displayedVCTopConstraint, displayedVCLeftConstraint, displayedVCWidthConstraint, displayedVCHeightConstraint]];
    
    [_selectedViewController didMoveToParentViewController:self];
    
    // Make iOS invoke selectedViewController viewDidAppear when the segmented view is already visible
    if (isViewAppeared)
    {
        [_selectedViewController endAppearanceTransition];
    }
}

#pragma mark - Search

- (void)showSearch:(BOOL)animated
{
    [super showSearch:animated];

    // Show the tabs header
    if (animated)
    {
        [UIView animateWithDuration:.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseIn
                         animations:^{

//                             self.selectionContainerHeightConstraint.constant = 44;
                             [self.view layoutIfNeeded];
                         }
                         completion:^(BOOL finished){
                         }];
    }
    else
    {
//        self.selectionContainerHeightConstraint.constant = 44;
        [self.view layoutIfNeeded];
    }
}

- (void)hideSearch:(BOOL)animated
{
    [super hideSearch:animated];

    // Hide the tabs header
    if (animated)
    {
        [UIView animateWithDuration:.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseIn
                         animations:^{

//                             self.selectionContainerHeightConstraint.constant = 0;
                             [self.view layoutIfNeeded];
                         }
                         completion:^(BOOL finished) {
                             // Go back to the main tab
                             // Do it at the end of the animation when the tabs header of the SegmentedVC is hidden
                             // so that the user cannot see the selection bar of this header moving
                             self.selectedIndex = 0;
                             self.selectedViewController.view.hidden = NO;
                         }];
    }
    else
    {
//        self.selectionContainerHeightConstraint.constant = 0;
        [self.view layoutIfNeeded];

        // Go back to the recents tab
        self.selectedIndex = 0;
        self.selectedViewController.view.hidden = NO;
    }
}

#pragma mark - touch event

- (void)onLabelTouch:(UIGestureRecognizer*)gestureRecognizer
{
    NSUInteger pos = [_segmentButtons indexOfObject:gestureRecognizer.view];
    // check if there is an update before triggering anything
    if ((pos != NSNotFound) && (_selectedIndex != pos))
    {
        UIButton* button = [_segmentButtons objectAtIndex: pos];
        [button setSelected:YES];

        UIButton* selectedButton = [_segmentButtons objectAtIndex: self.selectedIndex];
        [selectedButton setSelected:NO];

        // update the selected index
        self.selectedIndex = pos;
    }
}

@end
