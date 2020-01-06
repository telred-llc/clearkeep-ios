//
//  CKRoomDirectCreatingViewController.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/21/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

protocol CKRoomDirectCreatingViewControllerDelegate: class {
    func roomDirectCreating(withUserId userId: String, completion: ((_ success: Bool) -> Void)? )
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
    
    // MARK: - PROPERTY
    
    /**
     delegate
     */
    internal var delegate: CKRoomDirectCreatingViewControllerDelegate?
    
    /**
     data source
     */
    private var suggestedDataSource = [MXKContact]()

    private let disposeBag = DisposeBag()

    // MARK: - OVERRIDE

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // selection is enable
        self.tableView.allowsSelection = true
        
        // register cells
        self.tableView.register(CKRoomDirectCreatingSearchCell.nib, forCellReuseIdentifier: CKRoomDirectCreatingSearchCell.identifier)
        self.tableView.register(CKRoomDirectCreatingActionCell.nib, forCellReuseIdentifier: CKRoomDirectCreatingActionCell.identifier)
        self.tableView.register(CKRoomDirectCreatingSuggestedCell.nib, forCellReuseIdentifier: CKRoomDirectCreatingSuggestedCell.identifier)
        
        // Setup close button item
        let closeItemButton = UIBarButtonItem.init(
            image: UIImage(named: "back_button"),
            style: .plain,
            target: self, action: #selector(clickedOnBackButton(_:)))
        closeItemButton.theme.tintColor = themeService.attrStream { $0.navBarTintColor }
        
        // set nv items
        self.navigationItem.leftBarButtonItem = closeItemButton
        self.navigationItem.title = "New Conversation"
        self.navigationController?.navigationBar.tintColor = themeService.attrs.primaryTextColor
        self.navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")
        // first reload ds
        self.reloadDataSource()
        bindingTheme()
        UIApplication.shared.sendAction(#selector(UIApplication.resignFirstResponder), to: nil, from: nil, for: nil)
        self.hideKeyboardWhenTappedAround()
    }
    
    // MARK: - ACTION
    
    @objc func clickedOnBackButton(_ sender: Any?) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - PRIVATE

    func bindingTheme() {
        // Binding navigation bar color
        themeService.attrsStream.subscribe(onNext: { [weak self] (theme) in
            self?.defaultBarTintColor = themeService.attrs.navBarBgColor
            self?.barTitleColor = themeService.attrs.navBarTintColor
            self?.tableView.reloadData()
        }).disposed(by: disposeBag)

        themeService.rx
            .bind({ $0.navBarBgColor }, to: view.rx.backgroundColor, tableView.rx.backgroundColor)
            .disposed(by: disposeBag)
    }

    /**
     Reload suggested data source
     */
    private func reloadDataSource() {
        
        // reset
        self.suggestedDataSource.removeAll()
        
        // load them from ...
        let ds = MXKContactManager.shared().directMatrixContacts
            
        // loop in each
        for c in ds {
            
            // catch op
            if let c = c as? MXKContact {
                
                // add
                self.suggestedDataSource.append(c)
            }
        }
        
        // reload
        if suggestedDataSource.count > 0 {
            self.tableView.reloadSections(
                [Section.action.rawValue, Section.suggested.rawValue],
                with: .none)
        }
    }
    
    /**
     Action cell view
     */
    private func cellForAction(atIndexPath indexPath: IndexPath) -> CKRoomDirectCreatingActionCell {
        
        // dequeue
        if let cell = tableView.dequeueReusableCell(
            withIdentifier: CKRoomDirectCreatingActionCell.identifier,
            for: indexPath) as? CKRoomDirectCreatingActionCell {
            
            // none style selection
            cell.selectionStyle = .none
            
            // action
            cell.newGroupHandler = {
                
                // is navigation ?
                if let nvc = self.navigationController {
                    
                    // init
                    let vc = CKRoomCreatingViewController.instance()
                    
                    // import
                    vc.importSession(self.mxSessions)
                    
                    // push vc
                    nvc.pushViewController(vc, animated: true)
                } else {
                    
                    // init nvc
                    let nvc = CKRoomCreatingViewController.instanceNavigation(completion: { (vc: MXKViewController) in
                        
                        // import
                        vc.importSession(self.mxSessions)
                    })
                    
                    // present
                    self.present(nvc, animated: true, completion: nil)
                }
            }
            
            // new a group calling
            cell.newCallHandler = {
                // init
                let vc = CKRoomCallCreatingViewController.instance()
                
                // import
                vc.importSession(self.mxSessions)
                
                // push vc
                self.navigationController?.pushViewController(vc, animated: true)
            }

            cell.theme.backgroundColor = themeService.attrStream{ $0.cellPrimaryBgColor }
            return cell
        }
        return CKRoomDirectCreatingActionCell()
    }

    /**
     Suggested cell view
     */
    private func cellForSuggested(atIndexPath indexPath: IndexPath) -> CKRoomDirectCreatingSuggestedCell {
        
        // dequeue & confirm
        if let cell = tableView.dequeueReusableCell(
            withIdentifier: CKRoomDirectCreatingSuggestedCell.identifier,
            for: indexPath) as? CKRoomDirectCreatingSuggestedCell {
            
            // index of
            let contact = self.suggestedDataSource[indexPath.row]
                
            // display name
            cell.suggesteeLabel.text = contact.displayName
            cell.setAvatarUri(
                contact.matrixAvatarURL,
                identifyText: contact.displayName,
                session: self.mainSession)
            
            // status
            if let u = self.mainSession?.user(
                withUserId: (contact.matrixIdentifiers?.first as? String) ?? "") {
                cell.status = u.presence == MXPresenceOnline ? 1 : 0
            } else { cell.status = 0 }

            cell.suggesteeLabel.theme.textColor = themeService.attrStream{ $0.primaryTextColor }
            cell.theme.backgroundColor = themeService.attrStream{ $0.cellPrimaryBgColor }

            return cell
        }
        return CKRoomDirectCreatingSuggestedCell()
    }
    
    /**
     Searching - cell view
     */
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

        cell.theme.backgroundColor = themeService.attrStream{ $0.cellPrimaryBgColor }

        return cell
    }
    
    /**
     Title for header
     */
    private func titleForHeader(atSection section: Int) -> String {
        guard let s = Section(rawValue: section) else { return ""}
        
        switch s {
        case .search:
            return ""
        case .action:
            return "Probably you want"
        case .suggested:
            return "Suggested"
        }
    }
    
    /**
     Make a direct chat
     */
    private func directChat(atIndexPath indexPath: IndexPath) {
        self.tableView.allowsSelection = false
        // in range
        if suggestedDataSource.count > indexPath.row {
            
            // index of
            let c = suggestedDataSource[indexPath.row]
            
            // first
            if let userId = c.matrixIdentifiers.first as? String {
                
                // progress start
                self.startActivityIndicator()
                
                // invoke delegate
                self.delegate?.roomDirectCreating(withUserId: userId, completion: { (success: Bool) in
                    
                    // progress stop
                    self.stopActivityIndicator()
                    
                    // dismiss
                    if success == true { self.clickedOnBackButton(nil)}
                    self.tableView.allowsSelection = true
                })
            } else {
                self.tableView.allowsSelection = true
            }
        } else {
            self.tableView.allowsSelection = true
        }
    }
    
    private func finallySearchDirectoryUsers(byResponse response: MXUserSearchResponse?) {
        
        // sure is value response
        if let results = response?.results, results.count > 0 {
            
            // reset
            self.suggestedDataSource.removeAll()            
            
            // re-update
            for u in results {
                if let c = MXKContact(matrixContactWithDisplayName: u.displayname, andMatrixID: u.userId) {
                    self.suggestedDataSource.append(c)   
                }
            }
            
            // re-load
            self.tableView.reloadSections(
                [Section.action.rawValue, Section.suggested.rawValue],
                with: .none)
        } else {
            // no result
            self.suggestedDataSource.removeAll()
            self.tableView.reloadSections(
                [Section.action.rawValue, Section.suggested.rawValue],
                with: .none)
        }
    }
}

extension CKRoomDirectCreatingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let s = Section(rawValue: indexPath.section) else { return 0}
        
        switch s {
        case .search:
            return CKLayoutSize.Table.row44px
        case .action:
            return UITableViewAutomaticDimension
        case .suggested:
            return CKLayoutSize.Table.row60px
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let view = CKRoomHeaderInSectionView.instance() {
            view.theme.backgroundColor = themeService.attrStream{ $0.primaryBgColor }
            view.descriptionLabel?.text = self.titleForHeader(atSection: section)
            view.descriptionLabel?.font = UIFont.systemFont(ofSize: 21)
            view.descriptionLabel.theme.textColor = themeService.attrStream{ $0.primaryTextColor }
            return view
        }
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let s = Section(rawValue: section) else { return 0}
        switch s {
        case .search:
            return CGFloat.leastNonzeroMagnitude
        case .action:
            return CKLayoutSize.Table.row43px
        case .suggested:
            return CKLayoutSize.Table.row43px
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
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

extension CKRoomDirectCreatingViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}

