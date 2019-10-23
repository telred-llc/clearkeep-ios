//
//  CKContactListViewController.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/28/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation
import Contacts

protocol CKContactListViewControllerDelegate: class {
    func contactListCreating(withUserId userId: String, completion: ((_ success: Bool) -> Void)? )
}

final class CKContactListViewController: MXKViewController {
    
    // MARK: - OUTLET
    
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - ENUM
    
    struct Section {
        let letter : String
        let contacts : [MXKContact]
    }
    
    var sections = [Section]()
    
    // MARK: - PROPERTY
    
    internal weak var delegate: CKContactListViewControllerDelegate?
    
    /**
     Original data sources
     */
    private var originalMatrixSource = [MXKContact]()
    
    /**
     Filtered data sources
     */
    private var filteredMatrixSource: [MXKContact]!
    
    private var disposeBag = DisposeBag()
    
    // MARK: - CLASS
    
    public class func nib() -> UINib? {
        return UINib.init(
            nibName: CKContactListViewController.nibName,
            bundle: Bundle(for: self))
    }
    
    // MARK: - OVERRIDE
    
    override func loadView() {
        super.loadView()
        // load from xib
        if let nib = CKContactListViewController.nib() {
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
        self.delegate = controller as? CKContactListViewControllerDelegate
    }
}

// MARK: - PRIVATE

extension CKContactListViewController {
    
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
     Register table view cell
     */
    private func registerCells() {
        self.tableView.register(CKContactListMatrixCell.nib, forCellReuseIdentifier: CKContactListMatrixCell.identifier)
        self.tableView.theme.separatorColor = themeService.attrStream{ $0.separatorColor }
    }
    /**
     Reload data
     */
    private func reloadData() {
        self.reloadMatrixContacts()
        self.tableView.reloadData()
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
            self.filteredMatrixSource = self.originalMatrixSource.sorted(by: { (a, b) -> Bool in
                a.displayName < b.displayName
            })
            
            let groupedDictionary = Dictionary(grouping: self.filteredMatrixSource, by: {$0.displayName.prefix(1)})
            let keys = groupedDictionary.keys.sorted()
            
            self.sections = keys.map{ Section(letter: String($0), contacts: groupedDictionary[$0]!) }
            
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
        return CKLayoutSize.Table.row60px
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel.init()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = UIColor.blue
        label.text = sections[section].letter.localizedUppercase
        let headerView = UIView.init()
        headerView.addSubview(label)
        headerView.backgroundColor = CKColor.Background.tableView
        
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerView.leadingAnchor.constraint(equalTo: label.leadingAnchor, constant: -25),
            headerView.trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: 0),
            headerView.topAnchor.constraint(equalTo: label.topAnchor, constant: 0),
            headerView.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 0)
            ])
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.view.endEditing(true)
        
        let section = sections[indexPath.section]
        // in range
        if section.contacts.count > indexPath.row {
            
            // index of
            let c = section.contacts[indexPath.row]
            
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
        }    }
}

// MARK: - UITableViewDataSource

extension CKContactListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].contacts.count
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return self.sections.map{$0.letter}
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: CKContactListMatrixCell.identifier, for: indexPath) as! CKContactListMatrixCell
        let section = sections[indexPath.section]
        let contacts = section.contacts[indexPath.row]
        cell.displayNameLabel.text = contacts.displayName
        cell.setAvatarUri(
            contacts.matrixAvatarURL,
            identifyText: contacts.displayName,
            session: self.mainSession)
        
        if let mid = contacts.matrixIdentifiers?.first as? String {
            let u = self.mainSession.user(withUserId: mid)
            cell.status = ((u?.presence ?? MXPresenceUnavailable) == MXPresenceOnline) ? 1 : 0
        } else {
            cell.status = 0
        }
        
        return cell
    }
}
