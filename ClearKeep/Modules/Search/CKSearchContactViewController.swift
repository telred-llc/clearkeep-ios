//
//  CKSearchContactViewController.swift
//  Riot
//
//  Created by Sinbad Flyce on 8/6/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

import Foundation
import Contacts

protocol CKSearchContactViewControllerDelegate: class {
    func contactCreating(withUserId userId: String, completion: ((_ success: Bool) -> Void)? )
}

@objc final class CKSearchContactViewController: MXKViewController {
    
    // MARK: - OUTLET
    
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - ENUM
    
    private enum Section: Int {
        case directory = 0
        case matrix = 1
        case local = 2
        
        static func count() -> Int {
            return 3
        }
    }
    
    // MARK: - PROPERTY
    
    internal weak var delegate: CKSearchContactViewControllerDelegate?
    
    /**
     Original data sources
     */
    private var originalMatrixSource = [MXKContact]()
    private var originalLocalSource = [MXKContact]()
    
    /**
     Filtered data sources
     */
    private var filteredLocalSource: [MXKContact]!
    private var filteredMatrixSource: [MXKContact]!
    private var filteredDirectorySource: [MXKContact]!
    
    private var disposeBag = DisposeBag()
    
    // MARK: - CLASS
    
    @objc public class func objInstance() -> Self {
        return self.instance()
    }
    
    public class func nib() -> UINib? {
        return UINib.init(
            nibName: CKSearchContactViewController.nibName,
            bundle: Bundle(for: self))
    }
    
    // MARK: - OVERRIDE
    
    override func loadView() {
        super.loadView()
        // load from xib
        if let nib = CKSearchContactViewController.nib() {
            nib.instantiate(withOwner: self, options: nil)
            self.registerCells()
            self.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindingTheme()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Check whether the access to the local contacts has not been already asked.
        if CNContactStore.authorizationStatus(for: .contacts) == .notDetermined {
            MXKAppSettings.standard()?.syncLocalContacts = true
        }
    }
    
    // MARK: - OBJC
    
    @objc public func displayList(_ aRecentsDataSource: MXKRecentsDataSource!) {
        
        // sure this one
        guard let recentsDataSource = aRecentsDataSource else {
            return
        }
        
        self.importSession(recentsDataSource.mxSessions)
    }
    
    @objc public func scrollToNextRoomWithMissedNotifications() {
        // TODO
    }
    
    @objc public func setDelegate(_ controller: UIViewController) {
        self.delegate = controller as? CKSearchContactViewControllerDelegate
    }
    
    @objc public func search(_ text: String) {
        
        if text.count == 0 {
            self.filteredLocalSource = self.originalLocalSource
            self.filteredMatrixSource = self.originalMatrixSource
            self.filteredDirectorySource?.removeAll()

            // reload table view
            DispatchQueue.main.async {
                self.tableView?.reloadSections(
                    IndexSet([Section.directory.rawValue, Section.matrix.rawValue, Section.local.rawValue]), with: .none)
            }

            return
        }
        
        // filter local source
        self.filteredLocalSource?.removeAll()
        self.filteredLocalSource = self.originalLocalSource.filter({ (contact: MXKContact) -> Bool in
            let displayName = contact.displayName ?? ""
            return displayName.lowercased().contains(text.lowercased())
        })
        
        // filter matrix source
        self.filteredMatrixSource?.removeAll()
        self.filteredMatrixSource = self.originalMatrixSource.filter({ (contact: MXKContact) -> Bool in
            let displayName = contact.displayName ?? ""
            return displayName.lowercased().contains(text.lowercased())
        })
        
        // reload table view
        DispatchQueue.main.async {
            self.tableView.reloadSections(
                IndexSet([Section.matrix.rawValue, Section.local.rawValue]), with: .none)
        }
        
        // Seach users on Matrix server
        self.mainSession?.matrixRestClient.searchUsers(
            text, limit: 50, success: { (response: MXUserSearchResponse?) in
                
                // init
                self.filteredDirectorySource = [MXKContact]()
                
                // found! put them to filter array
                for mxUser in response?.results ?? [] {
                    if let mxContact = MXKContact(
                        matrixContactWithDisplayName: mxUser.displayname, andMatrixID: mxUser.userId) {
                        self.filteredDirectorySource.append(mxContact)
                    }
                }
                
                // reload table view
                DispatchQueue.main.async {
                    self.tableView.reloadSections(
                        IndexSet([Section.directory.rawValue]), with: .none)
                }
        }, failure: { (_) in
            // TODO
        })
    }

}

// MARK: - PRIVATE

extension CKSearchContactViewController {
    
    func bindingTheme() {
        // Binding navigation bar color
        themeService.attrsStream.subscribe(onNext: { [weak self] (theme) in
            self?.defaultBarTintColor = themeService.attrs.primaryBgColor
            self?.barTitleColor = themeService.attrs.primaryTextColor
            self?.tableView?.backgroundColor = theme.secondBgColor
            self?.tableView.reloadData()
        }).disposed(by: disposeBag)
    }
    
    /**
     Get a title for the header
     */
    private func titleForHeader(atSection section: Int) -> String {
        guard let s = Section(rawValue: section) else { return ""}
        
        switch s {
        case .matrix:
            return "MATRIX CONTACTS"
        case .directory:
            return "USER DIRECTORY"
        case .local:
            return "INVITE FROM CONTACTS"
        }
    }
    
    /**
     Register table view cell
     */
    private func registerCells() {
        self.tableView.register(CKContactListMatrixCell.nib, forCellReuseIdentifier: CKContactListMatrixCell.identifier)
        self.tableView.register(CKContactListLocalCell.nib, forCellReuseIdentifier: CKContactListLocalCell.identifier)
        self.tableView.theme.separatorColor = themeService.attrStream{ $0.separatorColor }
    }
    
    /**
     Cell for search
     */
    private func cellForSearch(_ indexPath: IndexPath) -> CKContactListSearchCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: CKContactListSearchCell.identifier, for: indexPath) as! CKContactListSearchCell
        
        // filtering
        cell.beginSearchingHandler = { text in
            
            // reload
            if text.count == 0 {
                self.reloadData()
            } else { // filtering
                
                // filter local source
                self.filteredLocalSource?.removeAll()
                self.filteredLocalSource = self.originalLocalSource.filter({ (contact: MXKContact) -> Bool in
                    let displayName = contact.displayName ?? ""
                    return displayName.lowercased().contains(text.lowercased())
                })
                
                // filter matrix source
                self.filteredMatrixSource?.removeAll()
                self.filteredMatrixSource = self.originalMatrixSource.filter({ (contact: MXKContact) -> Bool in
                    let displayName = contact.displayName ?? ""
                    return displayName.lowercased().contains(text.lowercased())
                })
                
                // reload table view
                DispatchQueue.main.async {
                    self.tableView.reloadSections(
                        IndexSet([Section.matrix.rawValue, Section.local.rawValue]), with: .none)
                }
            }
        }
        
        cell.searchBar.setTextFieldTextColor(color: themeService.attrs.primaryTextColor)
        return cell
    }
    
    /**
     Cell for matrix contact
     */
    private func cellForMatrix(_ indexPath: IndexPath) -> CKContactListMatrixCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: CKContactListMatrixCell.identifier, for: indexPath) as! CKContactListMatrixCell
        
        if let ds = self.filteredMatrixSource, !ds.isEmpty {
            
            cell.displayNameLabel.text = ds[indexPath.row].displayName
            
            cell.setAvatarUri(
                ds[indexPath.row].matrixAvatarURL,
                identifyText: ds[indexPath.row].displayName,
                session: self.mainSession)
            
            // status
            if let mid = ds[indexPath.row].matrixIdentifiers?.first as? String {
                let u = self.mainSession.user(withUserId: mid)
                cell.status = ((u?.presence ?? MXPresenceUnavailable) == MXPresenceOnline) ? 1 : 0
            } else {
                cell.status = 0
            }
        }
        return cell
    }
    
    /**
     Cell for Directory contact
     */
    private func cellForDirectory(_ indexPath: IndexPath) -> CKContactListMatrixCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: CKContactListMatrixCell.identifier, for: indexPath) as! CKContactListMatrixCell
        
        if let ds = self.filteredDirectorySource {
            cell.displayNameLabel.text = ds[indexPath.row].displayName
            cell.setAvatarUri(
                ds[indexPath.row].matrixAvatarURL,
                identifyText: ds[indexPath.row].displayName,
                session: self.mainSession)
            
            // status
            if let mid = ds[indexPath.row].matrixIdentifiers?.first as? String {
                let u = self.mainSession.user(withUserId: mid)
                cell.status = ((u?.presence ?? MXPresenceUnavailable) == MXPresenceOnline) ? 1 : 0
            } else {
                cell.status = 0
            }
        }
        return cell
    }
    
    /**
     Cell for local contact
     */
    private func cellForLocal(_ indexPath: IndexPath) -> CKContactListLocalCell {
        
        // deque
        let cell = self.tableView.dequeueReusableCell(withIdentifier: CKContactListLocalCell.identifier, for: indexPath) as! CKContactListLocalCell
        
        // ds
        if let ds = self.filteredLocalSource {
            
            // setup cell
            cell.setup(ds[indexPath.row])
        }
        
        // return
        return cell
    }
    
    /**
     Cell for Directory User
     */
    private func cellForEmptyDiretory(_ indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = "Here is the result of seaching user directory."
        cell.textLabel?.textColor = CKColor.Text.lightGray
        cell.textLabel?.font = UIFont.italicSystemFont(ofSize: 15)
        return cell;
    }
    
    /**
     Reload data
     */
    private func reloadData() {
        self.reloadLocalContacts()
        self.reloadMatrixContacts()
        self.tableView.reloadData()
    }
    
    /**
     Reload local contact
     */
    @objc private func reloadLocalContacts() {
        
        // shared locals
        if let localcs = MXKContactManager.shared().localContactsSplitByContactMethod as? [MXKContact] {
            
            // reset
            self.originalLocalSource.removeAll()
            
            // loop
            for c in localcs {
                
                // pick one, and it has email
                if let eas = c.emailAddresses, eas.count > 0 {
                    
                    // append
                    self.originalLocalSource.append(c)
                }
            }
            
            // assign fls to ols
            self.filteredLocalSource = self.originalLocalSource
        }
    }
    
    /**
     Reload matrix contact
     */
    private func reloadMatrixContacts() {
        
        // matrix contacts
        if let matrixcs = MXKContactManager.shared().directMatrixContacts as? [MXKContact] {
            
            // reset
            self.originalMatrixSource.removeAll()
            
            // pick one, and add to original source
            for c in matrixcs {
                self.originalMatrixSource.append(c)
            }
            
            // assign fms to oms
            self.filteredMatrixSource = self.originalMatrixSource
        }
    }
    
    /**
     Make a direct chat
     */
    private func directChat(atIndexPath indexPath: IndexPath, isUserDirectory: Bool) {
        
        let filter = isUserDirectory ? self.filteredDirectorySource : self.filteredMatrixSource
        
        // in range
        if (filter?.count ?? 0) > indexPath.row {
            
            // index of
            let c = filter?[indexPath.row]
            
            // first
            if let userId = c?.matrixIdentifiers.first as? String {
                
                // progress start
                if self.delegate != nil { self.startActivityIndicator() }
                
                // invoke delegate
                self.delegate?.contactCreating(withUserId: userId, completion: { (success: Bool) in
                    
                    // progress stop
                    self.stopActivityIndicator()
                })
            }
        }
    }
    
    /**
     Invite chat
     */
    private func inviteChat(atIndexPath indexPath: IndexPath) {
        
        // in range
        if self.filteredLocalSource.count > indexPath.row {
            
            // contact
            let c = self.filteredLocalSource[indexPath.row]
            
            // spin
            self.startActivityIndicator()
            
            // invite chat
            AppDelegate.the()?.inviteChat(c, completion: { (_) in
                self.stopActivityIndicator()
            })
        }
    }
    
    private func confirmInvitation(_ indexPath: IndexPath) {
        
        // do nothing if out range
        if self.filteredLocalSource.count <= indexPath.row {
            return
        }
        
        // contact
        let c = self.filteredLocalSource[indexPath.row]
        
        let name = c.displayName ?? (c.matrixIdentifiers.first as! MXKEmail).emailAddress
        
        // alert obj
        let alert = UIAlertController(
            title: "You want to invite \(name!) ?",
            message: nil,
            preferredStyle: .actionSheet)
        
        // leave room
        alert.addAction(UIAlertAction(title: "Invite", style: .default , handler:{ (_) in
            self.inviteChat(atIndexPath: indexPath)
        }))
        
        // cancel
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:{ (_) in
        }))
        
        // present
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: - UITableViewDelegate

extension CKSearchContactViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CKLayoutSize.Table.row60px
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let view = CKRoomHeaderInSectionView.instance() {
            view.descriptionLabel.text = self.titleForHeader(atSection: section)
            view.theme.backgroundColor = themeService.attrStream{ $0.tblHeaderBgColor }
            view.descriptionLabel.theme.textColor = themeService.attrStream{ $0.primaryTextColor }
            return view
        }
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CKLayoutSize.Table.defaultHeader
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.theme.backgroundColor = themeService.attrStream{ $0.secondBgColor }
        
        guard let s = Section(rawValue: indexPath.section) else { return}
        switch s {
        case .local:
            (cell as? CKContactListLocalCell)?.updateDisplay()
        default:
            return
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.view.endEditing(true)
        
        guard let s = Section(rawValue: indexPath.section) else { return}
        switch s {
        case .matrix:
            self.directChat(atIndexPath: indexPath, isUserDirectory: false)
        case .directory:
            self.directChat(atIndexPath: indexPath, isUserDirectory: true)
        case .local:
            self.confirmInvitation(indexPath)
        }
    }
}

// MARK: - UITableViewDataSource

extension CKSearchContactViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let s = Section(rawValue: section) else { return 0}
        
        switch s {
        case .matrix:
            return self.filteredMatrixSource != nil ? filteredMatrixSource.count : 0
        case .directory:
            let n = self.filteredDirectorySource?.count ?? 1
            return n == 0 ? 1 : n
        case .local:
            return self.filteredLocalSource != nil ? self.filteredLocalSource.count : 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let s = Section(rawValue: indexPath.section) else { return UITableViewCell()}
        
        switch s {
        case .matrix:
            return cellForMatrix(indexPath)
        case .directory:
            if filteredDirectorySource?.count ?? 0 > 0 {
                return cellForDirectory(indexPath)
            } else {
                return cellForEmptyDiretory(indexPath)
            }
        case .local:
            return cellForLocal(indexPath)
        }
    }
}
