/*
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

#import "UnifiedSearchViewController.h"

#import "UnifiedSearchRecentsDataSource.h"
#import "RecentsViewController.h"

#import "RoomDataSource.h"
#import "RoomViewController.h"

#import "DirectoryViewController.h"
#import "ContactDetailsViewController.h"
#import "SettingsViewController.h"

#import "HomeMessagesSearchViewController.h"
#import "HomeMessagesSearchDataSource.h"
#import "HomeFilesSearchViewController.h"
#import "FilesSearchCellData.h"

#import "AppDelegate.h"

#import "GBDeviceInfo_iOS.h"
#import "Riot-Swift.h"

@interface UnifiedSearchViewController ()
{
    RecentsViewController *recentsViewController;
    UnifiedSearchRecentsDataSource *recentsDataSource;

    HomeMessagesSearchViewController *messagesSearchViewController;
    CKHomeMessagesSearchDataSource *messagesSearchDataSource;
    
    HomeFilesSearchViewController *filesSearchViewController;
    CKHomeFilesSearchDataSource *filesSearchDataSource;
    
    CKSearchContactViewController *peopleSearchViewController;
    ContactsDataSource *peopleSearchDataSource;
    
    CKCallHistoryDataSource *callhistoryDatasource;
    CKCallHistoryViewController *callHistoryViewController;
    
    // Current alert (if any).
    UIAlertController *currentAlert;
}

@end

@implementation UnifiedSearchViewController

- (void)finalizeInit
{
    [super finalizeInit];
    
    // The navigation bar tint color and the rageShake Manager are handled by super (see SegmentedViewController).
}

- (void)viewDidLoad
{
    // Set up the SegmentedVC tabs before calling [super viewDidLoad]
    NSMutableArray* viewControllers = [[NSMutableArray alloc] init];
    NSMutableArray* titles = [[NSMutableArray alloc] init];

    [titles addObject: NSLocalizedStringFromTable(@"search_rooms", @"Vector", nil)];
    recentsViewController = [RecentsViewController recentListViewController];
    recentsViewController.enableSearchBar = NO;
    recentsViewController.screenName = @"UnifiedSearchRooms";
    [viewControllers addObject:recentsViewController];

    [titles addObject: NSLocalizedStringFromTable(@"search_messages", @"Vector", nil)];
    messagesSearchViewController = [HomeMessagesSearchViewController searchViewController];
    [viewControllers addObject:messagesSearchViewController];

    // Add search People tab
    [titles addObject: NSLocalizedStringFromTable(@"search_people", @"Vector", nil)];
    peopleSearchViewController = [CKSearchContactViewController objInstance];
    [peopleSearchViewController importSession:self.mxSessions];
    [peopleSearchViewController setDelegate:[AppDelegate theDelegate].masterTabBarController.homeViewController];
    [viewControllers addObject:peopleSearchViewController];
    
    // add Files tab
    [titles addObject: NSLocalizedStringFromTable(@"search_files", @"Vector", nil)];
    filesSearchViewController = [HomeFilesSearchViewController searchViewController];
    [viewControllers addObject:filesSearchViewController];

    [self initWithTitles:titles viewControllers:viewControllers defaultSelected:0];

    [super viewDidLoad];

    // Add the Riot background image when search bar is empty
    [self addBackgroundImageViewToView:self.view];
    
    // Initialize here the data sources if a matrix session has been already set.
    [self initializeDataSources];
    
    self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.searchBar.placeholder = NSLocalizedStringFromTable(@"search_default_placeholder", @"Vector", nil);

    [super showSearch:NO];
}

- (void)onPressRightMenuItem {
    [self.navigationController popViewControllerWithAnimated:NO completion:^{
        if (_didSelectCreateNewRoom) {
            _didSelectCreateNewRoom();
        }
    }];
}

- (void)userInterfaceThemeDidChange
{
    [super userInterfaceThemeDidChange];
    
    UIImageView *backgroundImageView = self.backgroundImageView;
    if (backgroundImageView)
    {
        UIImage *image = [MXKTools paintImage:backgroundImageView.image withColor:kRiotKeyboardColor];
        backgroundImageView.image = image;
    }
}

- (void)destroy
{
    [super destroy];

    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    self.searchBar.delegate = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Screen tracking
    [[Analytics sharedInstance] trackScreen:@"UnifiedSearch"];

    // Let's child display the loading not the home view controller
    if (self.activityIndicator)
    {
        [self.activityIndicator stopAnimating];
        self.activityIndicator = nil;
    }
    
    // Reset searches
    [recentsDataSource searchWithPatterns:nil];
    
    [self updateSearch];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Here the actual view size is available, check the background image display if any
    [self checkAndShowBackgroundImage];
    
    if (self.splitViewController && !self.splitViewController.isCollapsed)
    {
        // In case of split view controller where the primary and secondary view controllers are displayed side-by-side onscreen,
        // the selected room (if any) is highlighted.
        [self refreshCurrentSelectedCellInChild:YES];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    [self checkAndShowBackgroundImage];
}

#pragma mark -

- (MXEvent*)selectedSearchEvent
{
    if (messagesSearchViewController.selectedEvent)
    {
        return messagesSearchViewController.selectedEvent;
    }
    return filesSearchViewController.selectedEvent;
}

- (MXSession*)selectedSearchEventSession
{
    if (messagesSearchViewController.selectedEvent)
    {
        return messagesSearchDataSource.mxSession;
    }
    return filesSearchDataSource.mxSession;
}

#pragma mark -

- (void)initializeDataSources
{
    MXSession *mainSession = self.mainSession;
    
    if (mainSession)
    {
        // Init the recents data source
        recentsDataSource = [[UnifiedSearchRecentsDataSource alloc] initWithMatrixSession:mainSession];
        [recentsViewController displayList:recentsDataSource];
        
        // Init the search for messages
        messagesSearchDataSource = [[CKHomeMessagesSearchDataSource alloc] initWithMatrixSession:mainSession];
        [messagesSearchViewController displaySearch:messagesSearchDataSource];
        
        // Init the search for messages
        filesSearchDataSource = [[CKHomeFilesSearchDataSource alloc] initWithMatrixSession:mainSession];
        filesSearchDataSource.roomEventFilter.containsURL = YES;
        filesSearchDataSource.shouldShowRoomDisplayName = YES;
        [filesSearchDataSource registerCellDataClass:CKFilesSearchCellData.class forCellIdentifier:kMXKSearchCellDataIdentifier];
        [filesSearchViewController displaySearch:filesSearchDataSource];
        
        // Init the search for people
        peopleSearchDataSource = [[ContactsDataSource alloc] initWithMatrixSession:mainSession];
        peopleSearchDataSource.areSectionsShrinkable = YES;
        peopleSearchDataSource.displaySearchInputInContactsList = YES;
        peopleSearchDataSource.contactCellAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        // Check whether there are others sessions
        NSArray* mxSessions = self.mxSessions;
        if (mxSessions.count > 1)
        {
            for (MXSession *mxSession in mxSessions)
            {
                if (mxSession != mainSession)
                {
                    // Add the session to the recents data source
                    [recentsDataSource addMatrixSession:mxSession];
                    
                    // FIXME: Update messagesSearchDataSource and filesSearchDataSource
                }
            }
        }
    }
}

- (void)addMatrixSession:(MXSession *)mxSession
{
    // Check whether the controller's view is loaded into memory.
    if (recentsViewController)
    {
        // Check whether the data sources have been initialized.
        if (!recentsDataSource)
        {
            // Add first the session. The updated sessions list will be used during data sources initialization.
            [super addMatrixSession:mxSession];
            
            // Prepare data sources and return
            [self initializeDataSources];
            return;
        }
        else
        {
            // Add the session to the existing recents data source
            [recentsDataSource addMatrixSession:mxSession];
            
            // FIXME: Update messagesSearchDataSource and filesSearchDataSource
        }
    }
    
    [super addMatrixSession:mxSession];
}

- (void)removeMatrixSession:(MXSession *)mxSession
{
    [recentsDataSource removeMatrixSession:mxSession];
    
    // Check whether there are others sessions
    if (!recentsDataSource.mxSessions.count)
    {
        [recentsViewController displayList:nil];
        [recentsDataSource destroy];
        recentsDataSource = nil;
    }
    
    // FIXME: Handle correctly messagesSearchDataSource and filesSearchDataSource
    
    [super removeMatrixSession:mxSession];
}

- (void)showPublicRoomsDirectory
{
    // Force hiding the keyboard
    [self.searchBar resignFirstResponder];
    
    [self performSegueWithIdentifier:@"showDirectory" sender:self];
}

#pragma mark - Override MXKViewController

- (void)setKeyboardHeight:(CGFloat)keyboardHeight
{
    [self setKeyboardHeightForBackgroundImage:keyboardHeight];

    [super setKeyboardHeight:keyboardHeight];
    
    [self checkAndShowBackgroundImage];
}

- (void)startActivityIndicator
{
    // Redirect the operation to the currently displayed VC
    // It is a MXKViewController or a MXKTableViewController. So it supports startActivityIndicator
    [self.selectedViewController performSelector:@selector(startActivityIndicator)];
}

- (void)stopActivityIndicator
{
    // The selected view controller mwy have changed since the call of [self startActivityIndicator]
    // So, stop the activity indicator for all children
    for (UIViewController *viewController in self.viewControllers)
    {
        [viewController performSelector:@selector(stopActivityIndicator)];
    }
 }

#pragma mark - Override UIViewController+VectorSearch

- (void)setKeyboardHeightForBackgroundImage:(CGFloat)keyboardHeight
{
    [super setKeyboardHeightForBackgroundImage:keyboardHeight];

    if (keyboardHeight > 0)
    {
        [self checkAndShowBackgroundImage];
    }
}

// Check conditions before displaying the background
- (void)checkAndShowBackgroundImage
{
    self.backgroundImageView.hidden = YES;
}

#pragma mark - Override SegmentedViewController

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    [super setSelectedIndex:selectedIndex];

    if (self.selectedViewController == peopleSearchViewController)
    {
        self.searchBar.placeholder = NSLocalizedStringFromTable(@"search_people_placeholder", @"Vector", nil);
    }
    else
    {
        self.searchBar.placeholder = NSLocalizedStringFromTable(@"search_default_placeholder", @"Vector", nil);
    }
    
    [self updateSearch];
}

#pragma mark - Internal methods

// Made the currently displayed child update its selected cell
- (void)refreshCurrentSelectedCellInChild:(BOOL)forceVisible
{
    // TODO: Manage other children than recents
    [recentsViewController refreshCurrentSelectedCell:forceVisible];
    
    // CK is no longer to use it
    //[peopleSearchViewController refreshCurrentSelectedCell:forceVisible];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Keep ref on destinationViewController
    [super prepareForSegue:segue sender:sender];
    
    if ([[segue identifier] isEqualToString:@"showDirectory"])
    {
        DirectoryViewController *directoryViewController = segue.destinationViewController;
        [directoryViewController displayWitDataSource:recentsDataSource.publicRoomsDirectoryDataSource];
    }

    // Hide back button title
//    self.navigationItem.backBarButtonItem =[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
}

#pragma mark - Search

- (void)hideSearch:(BOOL)animated
{
    [self withdrawViewControllerAnimated:animated completion:nil];
}

// Update search results under the currently selected tab
- (void)updateSearch
{
    if (self.searchBar.text.length)
    {
        recentsDataSource.hideRecents = NO;
        self.backgroundImageView.hidden = YES;

        // Forward the search request to the data source
        if (self.selectedViewController == recentsViewController)
        {
            // Do a AND search on words separated by a space
            NSArray *patterns = [self.searchBar.text componentsSeparatedByString:@" "];

            [recentsDataSource searchWithPatterns:patterns];
            recentsViewController.shouldScrollToTopOnRefresh = YES;
        }
        else if (self.selectedViewController == messagesSearchViewController)
        {
            // Launch the search only if the keyboard is no more visible
            if (!self.searchBar.isFirstResponder)
            {
                // Do it asynchronously to give time to messagesSearchViewController to be set up
                // so that it can display its loading wheel
                dispatch_async(dispatch_get_main_queue(), ^{
                    [messagesSearchDataSource searchMessages:self.searchBar.text force:NO];
                    messagesSearchViewController.shouldScrollToBottomOnRefresh = NO;
                });
            }
        }
        else if (self.selectedViewController == peopleSearchViewController)
        {
            // CK is no longer to use this
            //[peopleSearchDataSource searchWithPattern:self.searchBar.text forceReset:NO];
            [peopleSearchViewController search:self.searchBar.text];
        }
        else if (self.selectedViewController == filesSearchViewController)
        {
            // Launch the search only if the keyboard is no more visible
            if (!self.searchBar.isFirstResponder)
            {
                // Do it asynchronously to give time to filesSearchViewController to be set up
                // so that it can display its loading wheel
                dispatch_async(dispatch_get_main_queue(), ^{
                    [filesSearchDataSource searchMessages:self.searchBar.text force:NO];
                    filesSearchViewController.shouldScrollToBottomOnRefresh = NO;
                });
            }
        }
    }
    else
    {
        // Nothing to search, show only the public dictionary
        recentsDataSource.hideRecents = YES;
        
        // Reset search result (if any)
        [recentsDataSource searchWithPatterns:nil];
        if (messagesSearchDataSource.searchText.length)
        {
            [messagesSearchDataSource searchMessages:nil force:NO];
        }
        
        [peopleSearchDataSource searchWithPattern:nil forceReset:NO];
        
        if (filesSearchDataSource.searchText.length)
        {
            [filesSearchDataSource searchMessages:nil force:NO];
        }
        
        [peopleSearchViewController search:@""];
    }
    
    [self checkAndShowBackgroundImage];
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (self.selectedViewController == recentsViewController)
    {
        // As the public room search is local, it can be updated on each text change
        [self updateSearch];
    }
    else if (self.selectedViewController == peopleSearchViewController)
    {
        // As the contact search is local, it can be updated on each text change
        [self updateSearch];
    }
    else if (!self.searchBar.text.length)
    {
        // Reset message search if any
        [self updateSearch];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    
    if (self.selectedViewController == messagesSearchViewController || self.selectedViewController == filesSearchViewController)
    {
        // As the messages/files search is done homeserver-side, launch it only on the "Search" button
        [self updateSearch];
    }
}

#pragma mark - ContactsTableViewControllerDelegate

- (void)contactsTableViewController:(ContactsTableViewController *)contactsTableViewController didSelectContact:(MXKContact*)contact
{
    // Force hiding the keyboard
    [self.searchBar resignFirstResponder];
    
    [[AppDelegate theDelegate].masterTabBarController selectContact:contact];
}

@end
