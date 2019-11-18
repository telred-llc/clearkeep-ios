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
    @IBOutlet weak var btnInvite: UIButton!
    
    // MARK: - ENUM
    
    private enum Section: Int {
        case search = 0
        case members = 1
        
        static func count() -> Int {
            return 2
        }
    }
    
    // MARK: - PROPERTY
    
    /**
     A filtered data source that contains mx contacts
     */
    private var filteredDataSource = [CKContactInternal]()
    
    var selectedUser = [CKContactInternal]()
    
    /**
     Room object
     */
    public var mxRoom: MXRoom!
    
    /**
     This controller probably displayed while you create new a room or add people to an existing room
     */
    public var isNewStarting: Bool = false

    private let disposeBag = DisposeBag()

    // MARK: - OVERRIDE
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(CKRoomAddingSearchCell.nib, forCellReuseIdentifier: CKRoomAddingSearchCell.identifier)
        self.tableView.register(CKRoomAddingMembersCell.nib, forCellReuseIdentifier: CKRoomAddingMembersCell.identifier)
        self.reloadDataSource()
        self.navigationItem.title = "Add Members"
        
        updateBarItems()
        self.hideKeyboardWhenTappedAround()
        
        // on new creating a room, may cancel inviting the members
        if self.isNewStarting {
            
            // Setup close button item
            let closeItemButton = UIBarButtonItem.init(
                image: UIImage(named: "ic_x_close"),
                style: .plain,
                target: self, action: #selector(clickedOnBackButton(_:)))
            closeItemButton.tintColor = themeService.attrs.navBarTintColor
            self.navigationItem.leftBarButtonItem = closeItemButton
        }

        addCustomBackButton()
        
        bindingTheme()
    }
    
    // MARK: - PRIVATE

    private func bindingTheme() {
        // Binding navigation bar color
        themeService.attrsStream.subscribe(onNext: { [weak self] (theme) in
            self?.defaultBarTintColor = themeService.attrs.navBarBgColor
            self?.barTitleColor = themeService.attrs.navBarTintColor
            self?.tableView?.reloadData()
        }).disposed(by: disposeBag)

        themeService.rx
            .bind({ $0.primaryBgColor }, to: view.rx.backgroundColor, tableView.rx.backgroundColor)
            .disposed(by: disposeBag)
    }

    @IBAction func clickInvite(_ sender: Any) {
        self.invite()
    }
    /**
     Reloading data source
     */
    private func reloadDataSource() {
        
        // reset
        self.filteredDataSource.removeAll()
        
        // fetch matrix contacts
        let mxcts = MXKContactManager.shared().directMatrixContacts
        
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
        
        // reload table view
        if self.filteredDataSource.count > 0 {
            self.tableView.reloadSections([1], with: .none)
        }        
    }
    
    private func cellForSearching(atIndexPath indexPath: IndexPath) -> CKRoomAddingSearchCell {
        let cell = (self.tableView.dequeueReusableCell(
            withIdentifier: CKRoomAddingSearchCell.identifier, for: indexPath) as? CKRoomAddingSearchCell) ?? CKRoomAddingSearchCell()

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

        cell.theme.backgroundColor = themeService.attrStream{ $0.primaryBgColor }
        return cell
    }
    
    private func cellForAddingMember(atIndexPath indexPath: IndexPath) -> CKRoomAddingMembersCell {
        if let cell = self.tableView.dequeueReusableCell(
            withIdentifier: CKRoomAddingMembersCell.identifier, for: indexPath) as? CKRoomAddingMembersCell {
            
            let d = self.filteredDataSource[indexPath.row]
            var checked = false
            
            let list = self.selectedUser.filter({ (user) -> Bool in
                user.mxContact.matrixIdentifiers.first as? String ?? "" == d.mxContact.matrixIdentifiers.first as? String ?? ""
            })
            
           if list.count > 0 {
            checked = true
            self.filteredDataSource[indexPath.row].isSelected = true
            }
            
            cell.displayNameLabel.text = d.mxContact.displayName
            cell.isChecked = checked
            cell.changesBy(mxContact: d.mxContact, inSession: self.mainSession)
            
            if let u = self.mainSession?.user(
                withUserId: (d.mxContact?.matrixIdentifiers?.first as? String) ?? "") {
                cell.status = u.presence == MXPresenceOnline ? 1 : 0
            } else { cell.status = 0 }

            cell.displayNameLabel.theme.textColor = themeService.attrStream{ $0.primaryTextColor }
            cell.theme.backgroundColor = themeService.attrStream{ $0.primaryBgColor }

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
            return "Suggested"
        }
    }
    
    private func updateBarItems() {
        
        let hasSelected = self.selectedUser.count > 0
        self.btnInvite.isEnabled = hasSelected
        let bgValid = UIImage(named: "bg_button_create")
        let bgNotValid = UIImage(named: "bg_btn_not_valid")

        if hasSelected {
            btnInvite.setBackgroundImage(bgValid, for: .normal)
        } else {
            btnInvite.setBackgroundImage(bgNotValid, for: .normal)
        }
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
        for c in self.selectedUser {
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
                
                // dismiss
                DispatchQueue.main.async {
                    self.dismiss(animated: true, completion: {
                        
                        // in new room?
                        if self.isNewStarting {
                            AppDelegate.the().masterTabBarController.selectRoom(withId: self.mxRoom.roomId, andEventId: nil, inMatrixSession: self.mxRoom.summary.mxSession) {}
                        }
                    })
                }
            }.catch { (error) in
        }
    }
    
    private func closeWithoutInvite() {
        self.dismiss(animated: true) {
            AppDelegate.the().masterTabBarController.selectRoom(withId: self.mxRoom.roomId, andEventId: nil, inMatrixSession: self.mxRoom.summary.mxSession) {}
        }
    }
    
    private func finallySearchDirectoryUsers(byResponse response: MXUserSearchResponse?) {
        
        // sure is value response
        if let results = response?.results, results.count > 0 {
            
            // reset
            self.filteredDataSource.removeAll()
            
            // re-update
            for u in results {
                if let c = MXKContact(matrixContactWithDisplayName: u.displayname, andMatrixID: u.userId) {
                    let ci = CKContactInternal(mxContact: c, isSelected: false)
                    self.filteredDataSource.append(ci)
                }
            }
            
            // re-load
            self.tableView.reloadSections([Section.members.rawValue], with: .none)
        } else {
            // no result
            self.filteredDataSource.removeAll()
            self.tableView.reloadSections([Section.members.rawValue], with: .none)
        }
    }
    
    @objc func clickedOnBackButton(_ sender: Any?) {
        self.closeWithoutInvite()
    }
}

// MARK: - Delegate
extension CKRoomAddingMembersViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.selectionStyle = .none
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let s = Section(rawValue: indexPath.section) else { return 1 }
        switch s {
        case .search:
            return CKLayoutSize.Table.row70px
        default:
            return CKLayoutSize.Table.row60px
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let view = CKRoomHeaderInSectionView.instance() {
            view.descriptionLabel?.text = self.titleForHeader(atSection: section)
            view.descriptionLabel.theme.textColor = themeService.attrStream{ $0.primaryTextColor }
            view.descriptionLabel.font = UIFont.systemFont(ofSize: 17)
            view.theme.backgroundColor = themeService.attrStream{ $0.tblHeaderBgColor }
            return view
        }
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UILabel()
        view.backgroundColor = .clear
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let s = Section(rawValue: section) else { return CGFloat.leastNonzeroMagnitude }
        switch s {
        case .search:
            return CGFloat.leastNonzeroMagnitude
        default:
            return CKLayoutSize.Table.defaultHeader
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
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
            if self.filteredDataSource[indexPath.row].isSelected {
                self.selectedUser.append(self.filteredDataSource[indexPath.row])
            }else {
                if let index = self.selectedUser.firstIndex(where: { (contact) -> Bool in
                    contact.mxContact.matrixIdentifiers.first as? String ?? "" == d.mxContact.matrixIdentifiers.first as? String ?? ""
                }){
                    self.selectedUser.remove(at: index)
                }
            }
            self.updateBarItems()
            self.tableView.reloadRows(at: [indexPath], with: .none)
            return
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !tableView.isDecelerating {
            view.endEditing(true)
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

extension CKRoomAddingMembersViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(CKRoomCreatingViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

