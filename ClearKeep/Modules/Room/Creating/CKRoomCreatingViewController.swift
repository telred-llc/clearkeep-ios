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
        
        static var count: Int { return 3}
    }
    
    // MARK: - PROPERTY        
    
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
    
    // MARK: - OVERRIDE
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.finalizeLoadView()
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
        self.tableView.allowsSelection = false
        
        // self is root view controller
        if self.navigationController?.viewControllers.first == self {
            
            // Setup close button item
            let closeItemButton = UIBarButtonItem.init(
                image: UIImage(named: "ic_x_close"),
                style: .plain,
                target: self, action: #selector(clickedOnBackButton(_:)))
            
            self.navigationItem.leftBarButtonItem = closeItemButton
        }
        
        // Setup right button item
        let rightItemButton = UIBarButtonItem.init(
            title: "Create",
            style: .plain, target: self,
            action: #selector(clickedOnCreateButton(_:)))
        
        rightItemButton.isEnabled = false

        // assign back button
        self.navigationItem.rightBarButtonItem = rightItemButton

        bindingTheme()
    }

    private func bindingTheme() {
        // Binding navigation bar color
        themeService.attrsStream.subscribe(onNext: { [weak self] (theme) in
            self?.defaultBarTintColor = themeService.attrs.primaryBgColor
            self?.barTitleColor = themeService.attrs.primaryTextColor
        }).disposed(by: disposeBag)

        themeService.rx
            .bind({ $0.secondBgColor }, to: view.rx.backgroundColor, tableView.rx.backgroundColor)
            .disposed(by: disposeBag)
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
            
            // public or private room
            if indexPath.row == 0 {
                cell.titleLabel.text = "Public"
                cell.desciptpionLabel.text = "Anyone in the Directory can join"
                cell.optionSwitch.isOn = creatingData.isPublic
                
                // bool value
                cell.valueChangedHandler = { isOn in
                    self.creatingData.isPublic = isOn
                }
                
            } else { // enable e2ee
                #if false
                cell.titleLabel.text = "Enable end to end encryption"
                cell.desciptpionLabel.text = "Once you enable e2ee, you can not disable it"
                cell.optionSwitch.isOn = creatingData.isE2ee
                
                // bool value
                cell.valueChangedHandler = { isOn in
                    self.creatingData.isE2ee = isOn
                }
                #endif
            }

            cell.theme.backgroundColor = themeService.attrStream{ $0.primaryBgColor }
            cell.titleLabel.theme.textColor = themeService.attrStream{ $0.primaryTextColor }
            cell.desciptpionLabel.theme.textColor = themeService.attrStream{ $0.secondTextColor }

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
            cell.nameTextField.text = creatingData.name
            
            // text value
            cell.edittingChangedHandler = { text in
                if let text = text {
                    self.creatingData.name = text
                    self.updateControls()
                }
            }

            cell.theme.backgroundColor = themeService.attrStream{ $0.primaryBgColor }
            cell.nameTextField.theme.textColor = themeService.attrStream{ $0.primaryTextColor }
            cell.nameTextField.attributedPlaceholder = NSAttributedString.init(string: "Name", attributes: [NSAttributedString.Key.foregroundColor: themeService.attrs.secondTextColor])

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
            
            // text value
            cell.edittingChangedHandler = { text in
                if let text = text {self.creatingData.topic = text}
            }

            cell.theme.backgroundColor = themeService.attrStream{ $0.primaryBgColor }
            cell.topicTextField.theme.textColor = themeService.attrStream{ $0.primaryTextColor }
            cell.topicTextField.attributedPlaceholder = NSAttributedString.init(string: "Briefly describle the topic of room", attributes: [NSAttributedString.Key.foregroundColor: themeService.attrs.secondTextColor])

            return cell
        }
        
        // default
        return CKRoomCreatingTopicCell()
    }

    private func updateControls() {
        // create button is enable or disable
        self.navigationItem.rightBarButtonItem?.isEnabled = creatingData.isValidated()
    }
    
    private func titleForHeader(atSection section: Int) -> String {
        guard let s = Section(rawValue: section) else { return ""}
        
        switch s {
        case .option:
            return ""
        case .name:
            return "Room name (Required)"
        case .topic:
            return "Room topic (Optional)"
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
        return CKLayoutSize.Table.row60px
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let view = CKRoomHeaderInSectionView.instance() {
            view.descriptionLabel?.text = self.titleForHeader(atSection: section)
            view.descriptionLabel.theme.textColor = themeService.attrStream{ $0.primaryTextColor }
            view.theme.backgroundColor = themeService.attrStream{ $0.secondBgColor }
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
        return CKLayoutSize.Table.defaultHeader
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
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
        }
    }
    
}
