//
//  CKContactListViewController.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/28/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

protocol CKContactListViewControllerDelegate: class {
    func contactListCreating(withUserId userId: String, completion: ((_ success: Bool) -> Void)? )
}

final class CKContactListViewController: MXKViewController {
    
    // MARK: - OUTLET
    
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - ENUM
    
    private enum Section: Int {
        case search = 0
        case matrix = 1
        case local = 2
        
        static func count() -> Int {
            return 3
        }
    }
    
    // MARK: - PROPERTY
    
    internal weak var delegate: CKContactListViewControllerDelegate?
    
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
    
    // MARK: - CLASS
    
    public class func nib() -> UINib? {
        return UINib.init(
            nibName: CKContactListViewController.nibName,
            bundle: Bundle(for: self))
    }
    
    // MARK: - OVERRIDE
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // load from xib
        if let nib = CKContactListViewController.nib() {
            nib.instantiate(withOwner: self, options: nil)
            self.tableView.reloadData()
            self.registerCells()
            self.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    // MARK: - OBJC
    
    @objc public func displayList(_ recentsDataSource: MXKRecentsDataSource) {
        self.importSession(recentsDataSource.mxSessions)
    }
    
    @objc public func scrollToNextRoomWithMissedNotifications() {
        // TODO
    }
    
    @objc public func setDelegate(_ controller: UIViewController) {
        self.delegate = controller as? CKContactListViewControllerDelegate
    }
}

// MARK: - PRIVATE

extension CKContactListViewController {
    
    /**
     Get a title for the header
     */
    private func titleForHeader(atSection section: Int) -> String {
        guard let s = Section(rawValue: section) else { return ""}
        
        switch s {
        case .search:
            return ""
        case .matrix:
            return "MATRIX CONTACTS"
        case .local:
            return "INVITE FROM CONTACTS"
        }
    }
    
    /**
     Register table view cell
     */
    private func registerCells() {
        self.tableView.register(CKContactListSearchCell.nib, forCellReuseIdentifier: CKContactListSearchCell.identifier)
        self.tableView.register(CKContactListMatrixCell.nib, forCellReuseIdentifier: CKContactListMatrixCell.identifier)
        self.tableView.register(CKContactListLocalCell.nib, forCellReuseIdentifier: CKContactListLocalCell.identifier)
    }
    
    /**
     Cell for search
     */
    private func cellForSearch(_ indexPath: IndexPath) -> CKContactListSearchCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: CKContactListSearchCell.identifier, for: indexPath) as! CKContactListSearchCell
        return cell
    }
    
    /**
     Cell for matrix contact
     */
    private func cellForMatrix(_ indexPath: IndexPath) -> CKContactListMatrixCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: CKContactListMatrixCell.identifier, for: indexPath) as! CKContactListMatrixCell
        
        if let ds = self.filteredMatrixSource {
            cell.displayNameLabel.text = ds[indexPath.row].displayName
            
            if let matUrl = ds[indexPath.row].matrixAvatarURL {
                cell.setMxAvatarUrl(matUrl, inSession: self.mainSession)
            } else {
                cell.photoView.image = AvatarGenerator.generateAvatar(forText: ds[indexPath.row].displayName)
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
     Reload data
     */
    private func reloadData() {
        self.reloadLocalContacts()
        self.reloadMatrixContacts()
    }
    
    /**
     Reload local contact
     */
    private func reloadLocalContacts() {
        
        // shared locals
        if let localcs = MXKContactManager.shared()?.localContactsSplitByContactMethod as? [MXKContact] {
            
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
        if let matrixcs = MXKContactManager.shared()?.directMatrixContacts as? [MXKContact] {
            
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
    private func directChat(atIndexPath indexPath: IndexPath) {
        
        // in range
        if self.filteredMatrixSource.count > indexPath.row {
            
            // index of
            let c = self.filteredMatrixSource[indexPath.row]
            
            // first
            if let userId = c.matrixIdentifiers.first as? String {
                
                // progress start
                if self.delegate != nil { self.startActivityIndicator() }
                
                // invoke delegate
                self.delegate?.contactListCreating(withUserId: userId, completion: { (success: Bool) in
                    
                    // progress stop
                    self.stopActivityIndicator()
                })
            }
        }
    }
}

// MARK: - UITableViewDelegate

extension CKContactListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let s = Section(rawValue: indexPath.section) else { return 1 }
        switch s {
        case .search:
            return CKLayoutSize.Table.row44px
        default:
            return CKLayoutSize.Table.row60px
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
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UILabel()
        view.backgroundColor = CKColor.Background.tableView
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let s = Section(rawValue: section) else { return 1}
        switch s {
        case .search:
            return CKLayoutSize.Table.header1px
        default:
            return CKLayoutSize.Table.header40px
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CKLayoutSize.Table.footer1px
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
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
        
        guard let s = Section(rawValue: indexPath.section) else { return}
        switch s {
        case .matrix:
            self.directChat(atIndexPath: indexPath)
        default:
            return
        }
    }
}

// MARK: - UITableViewDataSource

extension CKContactListViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let s = Section(rawValue: section) else { return 0}
        
        switch s {
        case .search:
            return 1
        case .matrix:
            return self.filteredMatrixSource != nil ? filteredMatrixSource.count : 0
        case .local:
            return self.filteredLocalSource != nil ? self.filteredLocalSource.count : 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let s = Section(rawValue: indexPath.section) else { return UITableViewCell()}
        
        switch s {
        case .search:
            return cellForSearch(indexPath)
        case .matrix:
            return cellForMatrix(indexPath)
        case .local:
            return cellForLocal(indexPath)
        }
    }
}
