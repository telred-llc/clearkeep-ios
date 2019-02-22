//
//  CKRoomSettingsEditViewController.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/16/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKRoomSettingsEditViewController: MXKViewController {
    
    // MARK: - CONST
    private let kEditableCellId     = CKRoomSettingsEditableCell.identifier
    private let kPhotoCellId        = CKRoomSettingsEditablePhotoCell.identifier
    
    // MARK: - ENUM
    
    private enum Status: Int {
        case display = 0
        case editting = 1
    }
    
    /**
     SectionType
     */
    private enum SectionType: Int {
        case name   = 0
        case image  = 1
        case topic  = 2
    }
    
    // MARK: - PROPERTY
    
    /**
     newTopic
     */
    private var newTopic: String!
    
    /**
     newName
     */
    private var newName: String!
    
    /**
     status
     */
    private var status: Status = .display
    
    /**
     doneItemButton
     */
    private var doneItemButton: UIBarButtonItem!

    /**
     MX Room
     */
    public var mxRoom: MXRoom!
    
    /**
     tableView
     */
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - IBAction
    
    @objc func clickedOnBackButton(_ sender: Any?) {
        if self.status == .display {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.view.endEditing(true)
        }
    }

    @objc func clickedOnDoneButton(_ sender: Any?) {
        self.onSave()
    }
    
    // MARK: - OVERRIDE
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.backgroundColor = CKColor.Background.tableView
        self.registerCells()
        self.resgisterNotifications()
        self.navigationItem.title = "Edit Room"                
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide default back button
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        // Setup done button items
        self.doneItemButton = UIBarButtonItem.init(
            title: "Done",
            style: .plain, target: self,
            action: #selector(clickedOnDoneButton(_:)))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.loadSessionData()
    }
    
    // MARK: - PRIVATE
    
    private func loadSessionData() {

        // reload table view
        self.tableView.reloadData()
    }
    
    private func registerCells() {
        
        // register cells
        self.tableView.register(CKRoomSettingsEditableCell.nib, forCellReuseIdentifier: kEditableCellId)
        self.tableView.register(CKRoomSettingsEditablePhotoCell.nib, forCellReuseIdentifier: kPhotoCellId)
    }
    
    private func resgisterNotifications() {
        
        // KeyboardWillShow
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyBoardWillShow(notification:)),
            name: NSNotification.Name.UIKeyboardWillShow, object: nil)

        // KeyboardWillhidden
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyBoardWillhidden(notification:)),
            name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    private func firedChangeStatus(_ status: Status) {
        if status == .display {
            self.navigationItem.rightBarButtonItem = nil
        } else if status == .editting {            
            self.navigationItem.rightBarButtonItem = doneItemButton
        }
    }
    
    /**
     On save
     */
    private func onSave() {
        
        self.view.endEditing(true)
        
        guard let room = self.mxRoom else {
            return
        }
        
        if (self.newTopic?.count ?? 0) > 0 {
            room.setTopic(self.newTopic) { (response: MXResponse<Void>) in
                if let error = response.error { print("[CK] Error - \(error.localizedDescription)")}
            }
        }
        
        if (self.newName?.count ?? 0) > 0 {
            room.summary.displayname = self.newName
            room.setName(self.newName) { (response: MXResponse<Void>) in
                if let error = response.error { print("[CK] Error - \(error.localizedDescription)")}
            }
        }
    }
    
    /**
     TITLE for table header
     */
    private func titleForTableHeader(_ section: Int) -> String? {
        guard let st = SectionType(rawValue: section) else {
            return nil
        }
        
        switch st {
        case .name:
            return "NAME"
        case .image:
            return "PHOTO"
        case .topic:
            return "CURRENT TOPIC"
        }
    }
}


// MARK: - UITableViewDelegate
extension CKRoomSettingsEditViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        // zero
        guard let st = SectionType(rawValue: indexPath.section) else {
            return 0
        }
        
        switch st {
        case .name:
            if self.mxRoom?.summary?.displayname != nil { return UITableViewAutomaticDimension}
            else { return CKLayoutSize.Table.row60px }
        case .image:
            return CKLayoutSize.Table.row60px
        case .topic:
            if self.mxRoom?.summary?.topic != nil { return UITableViewAutomaticDimension}
            else { return CKLayoutSize.Table.row60px }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let v = CKRoomHeaderInSectionView.instance()
        v?.descriptionLabel.text = self.titleForTableHeader(section)
        return v
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CKLayoutSize.Table.defaultHeader
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CKLayoutSize.Table.footer1px
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension CKRoomSettingsEditViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // sure being room is available
        guard let room = self.mxRoom, let st = SectionType(rawValue: indexPath.section) else {
            return UITableViewCell()
        }
        
        switch st {
        case .name:
            if let cell = tableView.dequeueReusableCell(
                withIdentifier: kEditableCellId,
                for: indexPath) as? CKRoomSettingsEditableCell {
                
                // cell display
                cell.textField.text = room.summary.displayname
                cell.textField.placeholder = "Set room name"
                
                // text changing
                cell.edittingChangedHandler = { text in
                    self.newName = text
                }
                
                // done keyboard
                cell.doneKeyboadHandler = {
                    self.onSave()
                }
                return cell
            }
        case .image:
            if let cell = tableView.dequeueReusableCell(
                withIdentifier: kPhotoCellId,
                for: indexPath) as? CKRoomSettingsEditablePhotoCell {
                
                // setup avatar
                cell.setAvatarUri(
                    mxRoom.summary.avatar,
                    identifyText: mxRoom.summary.roomId,
                    session: self.mainSession)
                return cell
            }
        case .topic:
            if let cell = tableView.dequeueReusableCell(
                withIdentifier: kEditableCellId,
                for: indexPath) as? CKRoomSettingsEditableCell {
                
                // cell display
                cell.textField.text = room.summary.topic
                cell.textField.placeholder = "Set topic"
                
                // text changing
                cell.edittingChangedHandler = { text in
                    self.newTopic = text
                }
                
                // done keyboard
                cell.doneKeyboadHandler = {
                    self.onSave()
                }

                return cell
            }
        }
        
        return UITableViewCell()
    }
}

// MARK: - CKRoomSettingsEditViewController (Keyboard)

extension CKRoomSettingsEditViewController {
    
    @objc private func keyBoardWillShow(notification: Notification) {
        self.status = .editting
        self.firedChangeStatus(.editting)
    }
    
    @objc private func keyBoardWillhidden(notification: Notification) {
        self.status = .display
        self.firedChangeStatus(.display)
    }
}

// MARK: - CKLabelInternal
fileprivate class CKLabelInternal: UILabel {
    
    // draw text with inset
    override func drawText(in rect: CGRect) {
        
        // make an inset rect
        let insets = UIEdgeInsetsMake(0, 20, 0, 5)
        
        // invoke your change to super
        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
    }
}
