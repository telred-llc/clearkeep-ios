//
//  CKRoomDirectCreatingViewController.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/21/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

protocol CKRoomDirectCreatingViewControllerDelegate: class {
    func roomDirectCreating(_ controller: CKRoomDirectCreatingViewController, didDirectChatWithUserId userId: String) -> Bool
}

final class CKRoomDirectCreatingViewController: MXKViewController {
    
    // MARK: - OUTLET
    
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - ENUM
    
    private enum Section: Int {
        case search = 0
        case action = 1
        case suggested = 2
        
        static func count() -> Int {
            return 3
        }
    }
    
    // MARK: - CLASS M
    
    class func instance() -> CKRoomDirectCreatingViewController {
        let instance = CKRoomDirectCreatingViewController(nibName: self.nibName, bundle: nil)
        return instance
    }
    
    class func instanceForNavigationController(completion: ((_ instance: CKRoomDirectCreatingViewController) -> Void)?) -> UINavigationController {
        let vc = self.instance()
        completion?(vc)
        return UINavigationController.init(rootViewController: vc)
    }
    
    // MARK: - PROPERTY
    
    /**
     delegate
     */
    internal var delegate: CKRoomDirectCreatingViewControllerDelegate?
    
    /**
     data source
     */
    private var suggestedDataSource = [MXKContact]()
    
    // MARK: - OVERRIDE

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.allowsSelection = true
        
        // register cells
        self.tableView.register(CKRoomDirectCreatingSearchCell.nib, forCellReuseIdentifier: CKRoomDirectCreatingSearchCell.identifier)
        self.tableView.register(CKRoomDirectCreatingActionCell.nib, forCellReuseIdentifier: CKRoomDirectCreatingActionCell.identifier)
        self.tableView.register(CKRoomDirectCreatingSuggestedCell.nib, forCellReuseIdentifier: CKRoomDirectCreatingSuggestedCell.identifier)
        
        // Setup back button item
        let backItemButton = UIBarButtonItem.init(
            title: "Back",
            style: .plain, target: self,
            action: #selector(clickedOnBackButton(_:)))
        
        self.navigationItem.leftBarButtonItem = backItemButton
        self.navigationItem.title = "New a conversation"
        self.reloadDataSource()
    }
    
    // MARK: - ACTION
    
    @objc func clickedOnBackButton(_ sender: Any?) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - PRIVATE
    
    /**
     Reload suggested data source
     */
    private func reloadDataSource() {
        
        // reset
        self.suggestedDataSource.removeAll()
        
        // load them from ...
        if let ds = MXKContactManager.shared()?.directMatrixContacts {
            for c in ds {
                if let c = c as? MXKContact {
                    self.suggestedDataSource.append(c)
                }
            }
        }
        
        // relod
        if suggestedDataSource.count > 0 { self.tableView.reloadData() }
    }
    
    private func cellForAction(atIndexPath indexPath: IndexPath) -> CKRoomDirectCreatingActionCell {
        if let cell = tableView.dequeueReusableCell(
            withIdentifier: CKRoomDirectCreatingActionCell.identifier,
            for: indexPath) as? CKRoomDirectCreatingActionCell {
            
            cell.selectionStyle = .none
            
            // action
            cell.newGroupHandler = {
                
                if let nvc = self.navigationController {
                    let vc = CKRoomCreatingViewController.instance()
                    vc.importSession(self.mxSessions)
                    nvc.pushViewController(vc, animated: true)
                    
                } else {
                    let nvc = CKRoomCreatingViewController.instanceForNavigationController(completion: { (vc: CKRoomCreatingViewController) in
                        vc.importSession(self.mxSessions)
                    })
                    self.present(nvc, animated: true, completion: nil)
                }
            }
            
            return cell
        }
        return CKRoomDirectCreatingActionCell()
    }

    private func cellForSuggested(atIndexPath indexPath: IndexPath) -> CKRoomDirectCreatingSuggestedCell {
        
        if let cell = tableView.dequeueReusableCell(
            withIdentifier: CKRoomDirectCreatingSuggestedCell.identifier,
            for: indexPath) as? CKRoomDirectCreatingSuggestedCell {
            
            let contact = self.suggestedDataSource[indexPath.row]
                
            // display name
            cell.suggesteeLabel.text = contact.displayName
            
            // avatar
            if let avtURL = self.mainSession.matrixRestClient.url(ofContent: contact.matrixAvatarURL) {
                cell.setAvatarImageUrl(urlString: avtURL, previewImage: nil)
            } else {
                cell.photoView.image = AvatarGenerator.generateAvatar(forText: contact.displayName)
            }
            
            return cell
        }
        return CKRoomDirectCreatingSuggestedCell()
    }
    
    private func cellForSeaching(atIndexPath indexPath: IndexPath) -> CKRoomDirectCreatingSearchCell {
        
        // sure to make cell
        let cell = (self.tableView.dequeueReusableCell(
            withIdentifier: CKRoomDirectCreatingSearchCell.identifier,
            for: indexPath) as? CKRoomDirectCreatingSearchCell) ?? CKRoomDirectCreatingSearchCell()
        
        // handl serching
        cell.beginSearchingHandler = { text in
            
            // indicator
            self.startActivityIndicator()
            
            // try to seach text in hs
            self.mainSession.matrixRestClient.searchUsers(text, limit: 50, success: { (response: MXUserSearchResponse?) in
                
                // main asyn
                DispatchQueue.main.async {
                    
                    // text lenght
                    if text.count > 0 {
                        
                        // seach
                        self.finallySearchDirectoryUsers(byResponse: response)
                    } else {
                        
                        // reload
                        self.reloadDataSource()
                    }
                    
                    self.stopActivityIndicator()
                }
            }, failure: { (_) in
                
                // main async
                DispatchQueue.main.async {
                    self.reloadDataSource()
                    self.stopActivityIndicator()
                }
            })
        }
        
        return cell
    }
    
    private func titleForHeader(atSection section: Int) -> String {
        guard let s = Section(rawValue: section) else { return ""}
        
        switch s {
        case .search:
            return ""
        case .action:
            return "PROBABLY YOU WANT"
        case .suggested:
            return "SUGGESTED (DIRECT MESSAGES)"
        }
    }
    
    /**
     Make a direct chat
     */
    private func directChat(atIndexPath indexPath: IndexPath) {
        if suggestedDataSource.count > indexPath.row {
            let c = suggestedDataSource[indexPath.row]
            if let userId = c.matrixIdentifiers.first as? String {
                if self.delegate?.roomDirectCreating(self, didDirectChatWithUserId: userId) == true {
                    self.clickedOnBackButton(nil)
                }
            }
        }
    }
    
    private func finallySearchDirectoryUsers(byResponse response: MXUserSearchResponse?) {
        
        // sure is value response
        if let results = response?.results, results.count > 0 {
            
            // reset
            self.suggestedDataSource.removeAll()
            self.tableView.reloadData()
            
            // re-update
            for u in results {
                if let c = MXKContact(matrixContactWithDisplayName: u.displayname, andMatrixID: u.userId) {
                    self.suggestedDataSource.append(c)
                }
            }
            
            // re-load
            self.tableView.reloadData()
            self.view.endEditing(true)
        }
    }
}

extension CKRoomDirectCreatingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let s = Section(rawValue: indexPath.section) else { return 0}
        
        switch s {
        case .search:
            return 44
        case .action:
            return 80
        case .suggested:
            return 60
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let view = CKRoomHeaderInSectionView.instance() {
            view.backgroundColor = CKColor.Background.tableView
            view.title = self.titleForHeader(atSection: section)
            return view
        }
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let s = Section(rawValue: section) else { return 0}
        switch s {
        case .search:
            return 1
        case .action:
            return 40
        case .suggested:
            return 40
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let s = Section(rawValue: indexPath.section) else { return }
        tableView.deselectRow(at: indexPath, animated: false)
        
        switch s {
        case .search:
            return
        case .action:
            return
        case .suggested:
            self.directChat(atIndexPath: indexPath)
            break
        }

    }
}

extension CKRoomDirectCreatingViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let s = Section(rawValue: section) else { return 0}
        
        switch s {
        case .search:
            return 1
        case .action:
            return 1
        case .suggested:
            return self.suggestedDataSource.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let s = Section(rawValue: indexPath.section) else { return CKRoomCreatingBaseCell()}
        
        switch s {
        case .search:
            return cellForSeaching(atIndexPath: indexPath)
        case .action:
            return self.cellForAction(atIndexPath: indexPath)
        case .suggested:
            return self.cellForSuggested(atIndexPath: indexPath)
        }
    }
    
    
}
