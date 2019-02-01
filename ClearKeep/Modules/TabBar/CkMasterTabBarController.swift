//
//  CkMasterTabBarController.swift
//  Riot
//
//  Created by Sinbad Flyce on 11/27/18.
//  Copyright © 2018 matrix.org. All rights reserved.
//

import Foundation

final public class CkMasterTabBarController: MasterTabBarController {
    
    lazy var placeholderSearchBar = UISearchBar()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.setupNavigationBar()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // hide navigation bar shadow
        navigationController?.navigationBar.shadowImage = UIImage()

        self.changeNavigationBar(color: CKColor.Background.navigationBar)
        navigationController?.view.setNeedsLayout() // force update layout
        navigationController?.view.layoutIfNeeded() // to fix height of the navigation bar
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // show navigation bar shadow
        navigationController?.navigationBar.shadowImage = nil
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
    
    private func setupNavigationBar() {
        placeholderSearchBar.sizeToFit()
        placeholderSearchBar.placeholder = NSLocalizedString("search_default_placeholder", tableName: "Vector", bundle: Bundle.main, value: "", comment: "")
        placeholderSearchBar.setShowsCancelButton(false, animated: false)
        placeholderSearchBar.delegate = self
        
        let searchBarContainer = CKSearchBarContainerView(customSearchBar: placeholderSearchBar)
        searchBarContainer.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 44)
        navigationItem.titleView = searchBarContainer
    }
}


