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
     backItemButton
     */
    private var backItemButton: UIBarButtonItem!

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
        
        // Setup back button item
        self.backItemButton = UIBarButtonItem.init(
            title: "Back",
            style: .plain, target: self,
            action: #selector(clickedOnBackButton(_:)))
        
        // Setup done button items
        self.doneItemButton = UIBarButtonItem.init(
            title: "Done",
            style: .plain, target: self,
            action: #selector(clickedOnDoneButton(_:)))

        self.navigationItem.leftBarButtonItem = backItemButton
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
            self.backItemButton.title = "Back"
            self.navigationItem.rightBarButtonItem = nil
        } else if status == .editting {
            self.backItemButton.title = "Cancel"
            self.navigationItem.rightBarButtonItem = doneItemButton
        }
    }
    
    private func onSave() {
        
        self.view.endEditing(true)
        
        guard let room = self.mxRoom else {
            return
        }
        
        if self.newTopic != nil {
            room.setTopic(self.newTopic) { (response: MXResponse<Void>) in
                if let error = response.error { print("[CK] Error - \(error.localizedDescription)")}
            }
        }
        
        if self.newName != nil {
            room.summary.displayname = self.newName
            room.setName(self.newName) { (response: MXResponse<Void>) in
                if let error = response.error { print("[CK] Error - \(error.localizedDescription)")}
            }
        }
    }
}


// MARK: - UITableViewDelegate
extension CKRoomSettingsEditViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        // section type
        guard let st = SectionType(rawValue: section) else {
            return nil
        }
        
        var titleSection = ""
        
        switch st {
        case .name:
            titleSection = "Name"
        case .image:
            titleSection = "Photo"
        case .topic:
            titleSection = "Current topic"
        }
        
        let label = CKLabelInternal()
        label.backgroundColor = #colorLiteral(red: 0.9763854146, green: 0.9765253663, blue: 0.9763547778, alpha: 1)
        label.text = titleSection
        label.font = CKAppTheme.mainLightAppFont(size: 15)
        label.textColor = #colorLiteral(red: 0.4352941176, green: 0.431372549, blue: 0.4509803922, alpha: 1)
        return label
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
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
                
                if let avtURL = self.mainSession.matrixRestClient.url(ofContent: mxRoom.summary.avatar) {
                    cell.setAvatarImageUrl(urlString: avtURL, previewImage: nil)
                }
                
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
