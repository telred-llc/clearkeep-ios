//
//  CKRoomCallCreatingViewController.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/31/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation
import PromiseKit

final class CKRoomCallCreatingViewController: MXKViewController {
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
    
    // MARK: - PROPERTY
    
    /**
     A filtered data source that contains mx contacts
     */
    private var filteredDataSource = [CKContactInternal]()

    private let disposeBag = DisposeBag()

    /**
     Room object
     */
    public var mxRoom: MXRoom!
    
    /**
     This controller probably displayed while you create new a room or add people to an existing room
     */
    public var isNewStarting: Bool = false
    
    private var stateCreateRoom: Bool = false {
        didSet {
            self.navigationItem.rightBarButtonItem?.isEnabled = stateCreateRoom
        }
    }
    
    // MARK: - OVERRIDE
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(CKRoomAddingSearchCell.nib, forCellReuseIdentifier: CKRoomAddingSearchCell.identifier)
        self.tableView.register(CKRoomAddingMembersCell.nib, forCellReuseIdentifier: CKRoomAddingMembersCell.identifier)
        self.reloadDataSource()
        self.navigationItem.title = "New Call"
        
        // Setup right button item
        let rightItemButton = UIBarButtonItem.init(
            title: "Create",
            style: .plain, target: self,
            action: #selector(clickedOnInviteButton(_:)))
        
        rightItemButton.isEnabled = false
        
        // assign right button
        self.navigationItem.rightBarButtonItem = rightItemButton
        bindingTheme()
    }
    
    // MARK: - PRIVATE

    private func bindingTheme() {
        // Binding navigation bar color
        themeService.attrsStream.subscribe(onNext: { [weak self] (theme) in
            self?.defaultBarTintColor = themeService.attrs.primaryBgColor
            self?.barTitleColor = themeService.attrs.primaryTextColor
            self?.tableView.reloadData()
        }).disposed(by: disposeBag)

        themeService.rx
            .bind({ $0.secondBgColor }, to: view.rx.backgroundColor, tableView.rx.backgroundColor)
            .disposed(by: disposeBag)
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
        if self.filteredDataSource.count > 0 { self.tableView.reloadData() }
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

        cell.backgroundColor = UIColor.clear
        cell.searchBar.setTextFieldTextColor(color: themeService.attrs.primaryTextColor)

        return cell
    }
    
    private func cellForAddingMember(atIndexPath indexPath: IndexPath) -> CKRoomAddingMembersCell {
        if let cell = self.tableView.dequeueReusableCell(
            withIdentifier: CKRoomAddingMembersCell.identifier, for: indexPath) as? CKRoomAddingMembersCell {
            
            let d = self.filteredDataSource[indexPath.row]
            
            cell.displayNameLabel.text = (d.mxContact.displayName != nil) ? d.mxContact.displayName : ((d.mxContact.emailAddresses.first) as! MXKEmail).emailAddress
            cell.isChecked = d.isSelected
            cell.changesBy(mxContact: d.mxContact, inSession: self.mainSession)

            cell.displayNameLabel.theme.textColor = themeService.attrStream{ $0.primaryTextColor }
            cell.theme.backgroundColor = themeService.attrStream{ $0.secondBgColor }

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

        self.stateCreateRoom = result // update state button
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
        
        // sure main session is available
        guard let mxMainSession = self.mainSession else {
            return
        }
        
        // number of invites
        var numberOfInvites = 0
        
        // start indicator
        self.startActivityIndicator()
        
        self.stateCreateRoom = false // update state button create room
        
        // finaly creating room
        let finalizeCreatingRoom = { (_ room: MXRoom?) -> Void in
            
            // then .able
            var thenables = [Promise<Bool>]()
            
            // build thenables
            for c in self.filteredDataSource {
                if c.isSelected {
                    thenables.append(self.promiseInvite(mxContact: c.mxContact))
                }
            }
            
            // nothing to invite
            if thenables.count == 0 {
                self.stopActivityIndicator()
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
                            
                            self.stateCreateRoom = true // update state button create room

                            // in new room?
                            if self.isNewStarting {
                                AppDelegate.the().masterTabBarController.selectRoom(withId: self.mxRoom.roomId, andEventId: nil, inMatrixSession: self.mxRoom.summary.mxSession) {}
                            }
                        })
                    }
                }.catch { (error) in
            }
        }
        
        // build room name
        var roomName: String = "Call: "
        var first = true
        
        // loop all selected items
        for c in self.filteredDataSource {
            
            // is selected?
            if c.isSelected {
                
                // increase
                numberOfInvites = numberOfInvites + 1
                
                // make room name by concatance
                roomName = first ? roomName + c.mxContact.displayName : roomName + ", " + c.mxContact.displayName
                
                // off first
                first = false
            }
        }
        
        // off course, this is a new call room
        self.isNewStarting = true
        
        // top-back creating calling room
        let _ = mxMainSession.createRoom(
            name: roomName,
            visibility: MXRoomDirectoryVisibility.private,
            alias: nil,
            topic: numberOfInvites <= 2 ?  "You are in 1:1 calling" : "You are in a conference calling",
            preset: nil) { (response: MXResponse<MXRoom>) in
                
                // sure room is ok
                guard let room = response.value else {
                    self.stopActivityIndicator()
                    return
                }
                
                // saved room
                self.mxRoom = room
                
                // sure it finshed encryption
                var isFinallyEncryption = false

                // 1 - 1 calling
                if numberOfInvites <= 2 {
                    room.enableEncryption(
                        withAlgorithm: kMXCryptoMegolmAlgorithm,
                        completion: { (_) in
                            
                            // finish creating room
                            
                            if isFinallyEncryption == false {
                                finalizeCreatingRoom(room)
                            }
                            
                            // finish
                            isFinallyEncryption = true
                    })
                } else { // video conferencing
                    finalizeCreatingRoom(room)
                }
        }
    }
    
    private func finallySearchDirectoryUsers(byResponse response: MXUserSearchResponse?) {
        
        // sure is value response
        if let results = response?.results, results.count > 0 {
            
            // reset
            self.filteredDataSource.removeAll()
            self.tableView.reloadData()
            
            // re-update
            for u in results {
                if let c = MXKContact(matrixContactWithDisplayName: u.displayname, andMatrixID: u.userId) {
                    let ci = CKContactInternal(mxContact: c, isSelected: false)
                    self.filteredDataSource.append(ci)
                }
            }
            
            // re-load
            self.tableView.reloadData()
            self.view.endEditing(true)
        }
    }
    
    // MARK: - ACTION
    @objc func clickedOnInviteButton(_ sender: Any?) {
        self.invite()
    }
    
}

// MARK: - Delegate
extension CKRoomCallCreatingViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.selectionStyle = .none
    }
    
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
            view.descriptionLabel.text = self.titleForHeader(atSection: section)
            view.descriptionLabel.theme.textColor = themeService.attrStream{ $0.primaryTextColor }
            view.theme.backgroundColor = themeService.attrStream{ $0.tblHeaderBgColor }
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
            self.updateBarItems()
            self.tableView.reloadRows(at: [indexPath], with: .none)
            return
        }
    }
}
// MARK: - Data source
extension CKRoomCallCreatingViewController: UITableViewDataSource {
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
