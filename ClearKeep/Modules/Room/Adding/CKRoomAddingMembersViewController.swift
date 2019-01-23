//
//  CKRoomAddingMembersViewController.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/22/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation
import PromiseKit

final class CKRoomAddingMembersViewController: MXKViewController {
    
    // MARK: - OUTLET
    
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - ENUM
    
    private enum Section: Int {
        case search = 0
        case members = 1
        
        static func count() -> Int {
            return 2
        }
    }
    
    // MARK: - CLASS M
    
    class func instance() -> CKRoomAddingMembersViewController {
        let instance = CKRoomAddingMembersViewController(nibName: self.nibName, bundle: nil)
        return instance
    }
    
    class func instanceForNavigationController(
        completion: ((_ instance: CKRoomAddingMembersViewController) -> Void)?) -> UINavigationController {
        let vc = self.instance()
        completion?(vc)
        return UINavigationController.init(rootViewController: vc)
    }
    
    // MARK: - PROPERTY
    
    /**
     A filtered data source that contains mx contacts
     */
    private var filteredDataSource = [CKContactInternal]()
    
    /**
     Room object
     */
    public var mxRoom: MXRoom!
    
    // MARK: - OVERRIDE
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(CKRoomAddingSearchCell.nib, forCellReuseIdentifier: CKRoomAddingSearchCell.identifier)
        self.tableView.register(CKRoomAddingMembersCell.nib, forCellReuseIdentifier: CKRoomAddingMembersCell.identifier)
        self.reloadDataSource()
        self.navigationItem.title = "Room Members"
        
        // Setup right button item
        let rightItemButton = UIBarButtonItem.init(
            title: "Invite",
            style: .plain, target: self,
            action: #selector(clickedOnInviteButton(_:)))
        
        rightItemButton.isEnabled = false
        
        // assign right button
        self.navigationItem.rightBarButtonItem = rightItemButton
    }
    
    // MARK: - PRIVATE
    
    /**
     Reloading data source
     */
    private func reloadDataSource() {
        
        // reset
        self.filteredDataSource.removeAll()
        
        // fetch matrix contacts
        if let mxcts = MXKContactManager.shared()?.directMatrixContacts {
            
            // loop all mxc
            for c in mxcts {
                
                // sure it is mxkcontact type
                if let c = c as? MXKContact {
                    
                    // ignore current user
                    if c.isMatchedMyUser(inSession: self.mainSession) { continue }
                    
                    // add each of them in the filtered
                    let ds = CKContactInternal(mxContact: c, isSelected: false)
                    self.filteredDataSource.append(ds)
                }
            }
        }
        
        // reload table view
        if self.filteredDataSource.count > 0 { self.tableView.reloadData() }
    }
    
    private func cellForSearching(atIndexPath indexPath: IndexPath) -> CKRoomAddingSearchCell {
        if let cell = self.tableView.dequeueReusableCell(
            withIdentifier: CKRoomAddingSearchCell.identifier, for: indexPath) as? CKRoomAddingSearchCell {
            return cell
        }
        return CKRoomAddingSearchCell()
    }
    
    private func cellForAddingMember(atIndexPath indexPath: IndexPath) -> CKRoomAddingMembersCell {
        if let cell = self.tableView.dequeueReusableCell(
            withIdentifier: CKRoomAddingMembersCell.identifier, for: indexPath) as? CKRoomAddingMembersCell {
            
            let d = self.filteredDataSource[indexPath.row]
            cell.displayNameLabel.text = d.mxContact.displayName
            cell.isChecked = d.isSelected
            cell.changesBy(mxContact: d.mxContact, inSession: self.mainSession)
            return cell
        }
        return CKRoomAddingMembersCell()
    }
    
    private func titleForHeader(atSection section: Int) -> String {
        guard let s = Section(rawValue: section) else { return ""}
        
        switch s {
        case .search:
            return ""
        case .members:
            return "SUGGESTED"
        }
    }
    
    private func updateBarItems() {
        var result = false
        for c in self.filteredDataSource {
            if c.isSelected {
                result = true
                break
            }
        }        
        self.navigationItem.rightBarButtonItem?.isEnabled = result
    }
    
    private func promiseInvite(mxContact contact: MXKContact!) -> Promise<Bool> {
        return Promise<Bool> { resolver in
            guard let userId = contact.matrixIdentifiers.first as? String else {
                resolver.fulfill(false)
                return
            }
            self.mxRoom.invite(.userId(userId), completion: { (response: MXResponse<Void>) in
                if let error = response.error {
                    resolver.reject(error)
                } else {
                    resolver.fulfill(response.isSuccess)
                }
            })
        }
    }
    
    private func invite() {
        
        // then .able
        var thenables = [Promise<Bool>]()
        
        // build thenables
        for c in self.filteredDataSource {
            if c.isSelected {
                thenables.append(promiseInvite(mxContact: c.mxContact))
            }
        }
        
        // nothing to invite
        if thenables.count == 0 {
            return
        }
        
        // process invitation by promises
        firstly { () -> Promise<[Bool]> in
            self.startActivityIndicator()
            return when(fulfilled: thenables)
            }.done { (results) in
                
            }.ensure {
                self.stopActivityIndicator()
            }.catch { (error) in
        }
    }
    
    // MARK: - ACTION
    @objc func clickedOnInviteButton(_ sender: Any?) {
        self.invite()                
    }
    
}

// MARK: - Delegate
extension CKRoomAddingMembersViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.selectionStyle = .none
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let s = Section(rawValue: indexPath.section) else { return 60}
        switch s {
        case .search:
            return 44
        default:
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
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UILabel()
        view.backgroundColor = CKColor.Background.tableView
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let s = Section(rawValue: section) else { return 1}
        switch s {
        case .search:
            return 1
        default:
            return 40
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        guard let s = Section(rawValue: indexPath.section) else { return}
        
        switch s {
        case .search:
            return
        case .members:
            let d = filteredDataSource[indexPath.row]
            self.filteredDataSource[indexPath.row].isSelected = !d.isSelected
            self.updateBarItems()
            self.tableView.reloadRows(at: [indexPath], with: .none)
            return
        }
    }
}
// MARK: - Data source
extension CKRoomAddingMembersViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let s = Section(rawValue: section) else { return 0}
        
        switch s {
        case .search:
            return 1
        case .members:
            return self.filteredDataSource.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let s = Section(rawValue: indexPath.section) else { return CKRoomBaseCell()}
        
        switch s {
        case .search:
            return self.cellForSearching(atIndexPath: indexPath)
        case .members:
            return self.cellForAddingMember(atIndexPath: indexPath)
        }
    }
}

// MARK: - CKContact Internal

fileprivate struct CKContactInternal {
    var mxContact: MXKContact!
    var isSelected: Bool = false
}

fileprivate extension MXKContact {
    
    /**
     Is matched my user in a session
     */
    func isMatchedMyUser(inSession session: MXSession!) -> Bool {
        
        // session is sure
        guard let session = session else {
            return false
        }
        
        // userId is sure
        guard let userId = session.myUser.userId else {
            return false
        }
        
        // contact id is sure
        guard let contactId = self.matrixIdentifiers.first as? String else {
            return false
        }
        
        // compare
        return userId == contactId
    }
}
