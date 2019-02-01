//
//  CkMasterTabBarController.swift
//  Riot
//
//  Created by Sinbad Flyce on 11/27/18.
//  Copyright © 2018 matrix.org. All rights reserved.
//

import Foundation

extension MasterTabBarController {
    @objc func reflectingBadges() {}
}

final public class CkMasterTabBarController: MasterTabBarController {
    
    lazy var placeholderSearchBar = UISearchBar.init(frame: CGRect.zero)
    
    let kHomeTabIndex       = 0
    let kHomeFavouriteIndex = 1
    let kHomeContactIndex   = 2
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        placeholderSearchBar.sizeToFit()
        placeholderSearchBar.placeholder = NSLocalizedString("search_default_placeholder", tableName: "Vector", bundle: Bundle.main, value: "", comment: "")
        placeholderSearchBar.setShowsCancelButton(false, animated: false)
        placeholderSearchBar.delegate = self
        self.navigationController?.navigationBar.topItem?.titleView = placeholderSearchBar
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.changeNavigationBar(color: CKColor.Background.navigationBar)
    }
    
    public override func showAuthenticationScreen() {

        if self.authViewController == nil && self.isCkAuthViewControllerPreparing == false {
            self.isCkAuthViewControllerPreparing = true
            AppDelegate.the()?.restoreInitialDisplay({
                self.performSegue(withIdentifier: "showAuth", sender: self)
            })
        }
    }
    
    public override func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        if let searchVC = UIStoryboard.init(name: "MainEx", bundle: nil).instantiateViewController(withIdentifier: "UnifiedSearchViewController") as? UnifiedSearchViewController {
            searchVC.importSession(self.mxSessions)
            self.navigationController?.pushViewController(searchVC, animated: false)
        }
        return false
    }
    
    public override func reflectingBadges() {
        
        // missed count
        var missedCount = self.missedDiscussionsCount() + self.missedHighlightDiscussionsCount()
        
        // missed count
        if missedCount == 0 {
            
            // loop via sessions
            for session in self.mxSessions {
                
                // sure it ok
                guard let session = session as? MXSession else {
                    continue
                }
                
                // SUM unread
                for room in session.roomsSummaries() {
                    missedCount += room.localUnreadEventCount > 0 ? 1 : 0
                }
            }
        }
        
        // is not zero
        if missedCount > 0 {
            
            // update badge
            self.tabBar.items?[kHomeTabIndex].badgeValue = self.tabBarBadgeStringValue(missedCount)
        } else {
            
            // zero badge
            self.tabBar.items?[kHomeTabIndex].badgeValue = nil
        }
    }
}
