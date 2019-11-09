//
//  CKRoomCreatingViewController.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/19/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

/**
 ROOM creating data
 */
private struct RoomCreatingData {
    var isPublic: Bool
    var isE2ee: Bool
    var name: String
    var topic: String
    
    static func == (lhs: inout RoomCreatingData, rhs: RoomCreatingData) -> Bool {
        return (lhs.isPublic == rhs.isPublic
            && lhs.isE2ee == rhs.isE2ee
            && lhs.name == rhs.name
            && lhs.topic == rhs.topic)
    }
    
    func isValidated() -> Bool {
        return self.name.count > 0
    }
}

/**
 Controller class
 */
final class CKRoomCreatingViewController: MXKViewController {
    
    // MARK: - OUTLET
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - ENUM
    
    private enum Section: Int {
        case name   = 0
        case topic  = 1
        case option = 2
        case suggested = 3
        static var count: Int { return 4}
    }
    
    // MARK: - PROPERTY        
    
    private var filteredDataSource = [CKContactInternal]()
    var selectedUser = [CKContactInternal]()
    
    /**
     VAR room creating data
     */
    private var creatingData = RoomCreatingData(
        isPublic: false,
        isE2ee: true,
        name: "",
        topic: "")
    
    private var request: MXHTTPOperation!
    private let disposeBag = DisposeBag()
    
    @IBOutlet weak var btnCreate: UIButton!
    
    
    private var stateCreateRoom: Bool = false {
        didSet {
            let bgValid = UIImage(named: "bg_button_create")
            let bgNotValid = UIImage(named: "bg_btn_not_valid")
            btnCreate.isEnabled = stateCreateRoom
            if stateCreateRoom {
                btnCreate.setBackgroundImage(bgValid, for: .normal)
            } else {
                btnCreate.setBackgroundImage(bgNotValid, for: .normal)
            }
        }
    }
    
    // MARK: - OVERRIDE
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.finalizeLoadView()
        self.reloadDataSource()
        self.hideKeyboardWhenTappedAround()
    }
    
    deinit {
        if request != nil {
            request.cancel()
            request = nil
        }
    }
    
    // MARK: - PRIVATE
    
    private func finalizeLoadView() {
        
        // title
        self.navigationItem.title = "New Room"
        
        // register cells
        self.tableView.register(CKRoomCreatingOptionsCell.nib, forCellReuseIdentifier: CKRoomCreatingOptionsCell.identifier)
        self.tableView.register(CKRoomCreatingTopicCell.nib, forCellReuseIdentifier: CKRoomCreatingTopicCell.identifier)
        self.tableView.register(CKRoomCreatingNameCell.nib, forCellReuseIdentifier: CKRoomCreatingNameCell.identifier)
        self.tableView.register(CKRoomAddingMembersCell.nib, forCellReuseIdentifier: CKRoomAddingMembersCell.identifier)
        
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        
        self.setNavigationBar()
        bindingTheme()
    }
    
    func setNavigationBar(){
        let closeItemButton = UIBarButtonItem.init(
            image: UIImage(named: "ic_back_nav"),
            style: .plain,
            target: self, action: #selector(clickedOnBackButton))
        self.navigationItem.leftBarButtonItem = closeItemButton
    }
    
    private func bindingTheme() {
        // Binding navigation bar color
        themeService.attrsStream.subscribe(onNext: { [weak self] (theme) in
            self?.defaultBarTintColor = themeService.attrs.primaryBgColor
            self?.barTitleColor = themeService.attrs.primaryTextColor
        }).disposed(by: disposeBag)
        
        themeService.rx
            .bind({ $0.primaryBgColor }, to: view.rx.backgroundColor, tableView.rx.backgroundColor)
            .disposed(by: disposeBag)
    }
    
    @IBAction func onClickCreate(_ sender: Any) {
        self.createRoom()
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
    
    
    
    /**
     This function to help our class make a new room
     */
    private func createRoom() {
        
        // sure main session is available
        guard let mxMainSession = self.mainSession else {
            return
        }
        
        if self.creatingData.isValidated() == false {
            return
        }
        
        // standard ux
        self.view.endEditing(true)
        self.startActivityIndicator()
        self.stateCreateRoom = false // update state button create room
        
        // starting to attemp creating room
        self.request = mxMainSession.createRoom(
            name: creatingData.name,
            visibility: creatingData.isPublic ? MXRoomDirectoryVisibility.public : MXRoomDirectoryVisibility.private,
            alias: nil,
            topic: creatingData.topic,
            preset: nil) { (response: MXResponse<MXRoom>) in
                
                // a closure finishing room
                let finalizeCreatingRoom = { (_ room: MXRoom?) -> Void in
                    
                    // reset request
                    self.request = nil
                    self.stopActivityIndicator()
                    
                    // dismiss
                    DispatchQueue.main.async {
                        let vc = CKRoomAddingMembersViewController.instance()
                        vc.importSession(self.mxSessions)
                        vc.mxRoom = room
                        vc.isNewStarting = true
                        vc.selectedUser = self.selectedUser
                        
                        self.stateCreateRoom = true // update state button create room
                        
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                }
                
                // sure it finshed encryption
                var isFinallyEncryption = false
                
                // enable e233
                if let room = response.value, self.creatingData.isE2ee == true {
                    self.request = room.enableEncryption(
                        withAlgorithm: kMXCryptoMegolmAlgorithm,
                        completion: { (response2: MXResponse<Void>) in
                            
                            // finish creating room
                            if isFinallyEncryption == false {
                                finalizeCreatingRoom(room)
                            }
                            
                            // finish
                            isFinallyEncryption = true
                    })
                } else {
                    // finish creating room
                    finalizeCreatingRoom(response.value)
                }
        }
    }
    
    private func cellForOptions(atIndexPath indexPath: IndexPath) -> CKRoomCreatingOptionsCell {
        
        // dequeue cell
        if let cell = tableView.dequeueReusableCell(
            withIdentifier: CKRoomCreatingOptionsCell.identifier,
            for: indexPath) as? CKRoomCreatingOptionsCell {
            cell.selectionStyle = .none
            // public or private room
            if indexPath.row == 0 {
                cell.isChecked = creatingData.isPublic
                
                // bool value
                cell.valueChangedHandler = { isOn in
                    self.creatingData.isPublic = isOn
                }
                
            }
            
            return cell
        }
        
        // default
        return CKRoomCreatingOptionsCell()
    }
    
    private func cellForName(atIndexPath indexPath: IndexPath) -> CKRoomCreatingNameCell {
        
        // dequeue room name cell
        if let cell = tableView.dequeueReusableCell(
            withIdentifier: CKRoomCreatingNameCell.identifier,
            for: indexPath) as? CKRoomCreatingNameCell {
            cell.nameTextField.delegate = self
            cell.nameTextField.tag = 1
            cell.selectionStyle = .none
            // text value
            cell.edittingChangedHandler = { text in
                if let text = text {
                    self.creatingData.name = text
                    cell.nameTextField.text = text
                    self.updateControls()
                }
            }
            return cell
        }
        
        // default
        return CKRoomCreatingNameCell()
    }
    
    private func cellForTopic(atIndexPath indexPath: IndexPath) -> CKRoomCreatingTopicCell {
        
        // dequeue cell
        if let cell = tableView.dequeueReusableCell(
            withIdentifier: CKRoomCreatingTopicCell.identifier,
            for: indexPath) as? CKRoomCreatingTopicCell {
            cell.topicTextField.text = creatingData.topic
            cell.selectionStyle = .none
            cell.topicTextField.tag = 99
            cell.topicTextField.delegate = self
            // text value
            cell.edittingChangedHandler = { text in
                if let text = text {self.creatingData.topic = text}
            }
            return cell
        }
        
        // default
        return CKRoomCreatingTopicCell()
    }
    
    private func cellForSuggested(atIndexPath indexPath: IndexPath) -> CKRoomAddingMembersCell{
        if let cell = tableView.dequeueReusableCell(
            withIdentifier: CKRoomAddingMembersCell.identifier,
            for: indexPath) as? CKRoomAddingMembersCell {
            let d = self.filteredDataSource[indexPath.row]
            cell.displayNameLabel.text = (d.mxContact.displayName != nil) ? d.mxContact.displayName : ((d.mxContact.emailAddresses.first) as! MXKEmail).emailAddress
            cell.isChecked = d.isSelected
            cell.changesBy(mxContact: d.mxContact, inSession: self.mainSession)
            cell.selectionStyle = .none
            cell.displayNameLabel.theme.textColor = themeService.attrStream{ $0.primaryTextColor }
            return cell
        }
        return CKRoomAddingMembersCell()
    }
    
    private func updateControls() {
        // create button is enable or disable
        self.stateCreateRoom = creatingData.isValidated()
    }
    
    private func titleForHeader(atSection section: Int) -> String {
        guard let s = Section(rawValue: section) else { return ""}
        
        switch s {
        case .option:
            return ""
        case .name:
            return ""
        case .topic:
            return ""
        case .suggested:
            return "Suggested"
        }
    }
    
    // MARK: - ACTION
    
    @objc func clickedOnBackButton(_ sender: Any?) {
        if self.navigationController?.viewControllers.first != self {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func clickedOnCreateButton(_ sender: Any?) {
        self.createRoom()
    }
}

// MARK: - UITableViewDelegate

extension CKRoomCreatingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let s = Section(rawValue: indexPath.section) else { return 0}

        switch s {
        case .suggested:
            return CKLayoutSize.Table.row60px
        case .name:
            return UITableViewAutomaticDimension
        case .topic:
            return UITableViewAutomaticDimension
        default:
            return CKLayoutSize.Table.row44px
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let view = CKRoomHeaderInSectionView.instance() {
            view.descriptionLabel?.text = self.titleForHeader(atSection: section)
            
            let s = Section(rawValue: section)
            switch s {
            case .name? :
                view.descriptionLabel.textColor = CKColor.Text.blue
                view.theme.backgroundColor = themeService.attrStream{ $0.tblHeaderBgColor }
                break
            case .suggested?:
                view.descriptionLabel.textColor = #colorLiteral(red: 0.2666666667, green: 0.2666666667, blue: 0.2666666667, alpha: 1)
                view.descriptionLabel.font = UIFont.systemFont(ofSize: 19)
                view.theme.backgroundColor = themeService.attrStream{ $0.tblHeaderBgColor }
                break
            default :
                view.descriptionLabel.textColor = CKColor.Text.lightGray
                view.descriptionLabel.font = UIFont.systemFont(ofSize: 15)
                view.backgroundColor = .clear
                break
            }
            
            return view
        }
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UILabel()
        view.backgroundColor = UIColor.clear
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let s = Section(rawValue: section) else { return 0}
        switch s {
        case .name , .topic:
            return CGFloat.leastNonzeroMagnitude
        case .suggested:
            return CKLayoutSize.Table.row43px
        default:
            return CKLayoutSize.Table.defaultHeader
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !tableView.isDecelerating {
            view.endEditing(true)
        }
    }
}

// MARK: - UITableViewDataSource

extension CKRoomCreatingViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // sure to work
        guard let s = Section(rawValue: section) else { return 0 }
        
        // number rows in case
        switch s {
        case .option: return 1
        case .name: return 1
        case .topic: return 1
        case .suggested: return self.filteredDataSource.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // sure to work
        guard let s = Section(rawValue: indexPath.section) else { return CKRoomCreatingBaseCell() }
        
        switch s {
        case .option:
            
            // room options cell
            return cellForOptions(atIndexPath: indexPath)
        case .name:
            
            // room name cell
            return cellForName(atIndexPath: indexPath)
        case .topic:
            
            // room topic cell
            return cellForTopic(atIndexPath: indexPath)
        case .suggested:
            return cellForSuggested(atIndexPath: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if Section(rawValue: indexPath.section) == Section.suggested {
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
            
            self.tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
    
}

extension CKRoomCreatingViewController : UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.tag == 1 {
            let fieldNext = self.view.viewWithTag(99) as? UITextField
            fieldNext?.becomeFirstResponder()
        }
        if textField.tag == 99 {
            self.view.endEditing(true)
        }
        return true
    }
}

extension CKRoomCreatingViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(CKRoomCreatingViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: - CKContact Internal
struct CKContactInternal {
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

