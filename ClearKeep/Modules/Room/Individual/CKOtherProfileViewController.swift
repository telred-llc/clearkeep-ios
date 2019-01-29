//
//  CKOtherProfileViewController.swift
//  Riot
//
//  Created by Hiếu Nguyễn on 1/23/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

class CKOtherProfileViewController: MXKViewController {
    // MARK: - OUTLET
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - ENUM
    
    private enum Section: Int {
        case avatar  = 0
        case action  = 1
        case detail  = 2
        
        static var count: Int { return 3}
    }
    
    // MARK: - CLASS
    
    class func instance() -> CKOtherProfileViewController {
        let instance = CKOtherProfileViewController(nibName: self.nibName, bundle: nil)
        return instance
    }
    
    class func instanceForNavigationController(completion: ((_ instance: CKOtherProfileViewController) -> Void)?) -> UINavigationController {
        let vc = self.instance()
        completion?(vc)
        return UINavigationController.init(rootViewController: vc)
    }
    
    // MARK: - PROPERTY
    
    /**
     MX Room
     */
    public var mxRoom: MXRoom!
    public var mxNumber: [MXRoomMember]! = [MXRoomMember]()
    private var request: MXHTTPOperation!
    
    
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
        
        // register cells
        self.tableView.register(CKAccountProfileAvatarCell.nib, forCellReuseIdentifier: CKAccountProfileAvatarCell.identifier)
        self.tableView.register(CKOtherProfileActionCell.nib, forCellReuseIdentifier: CKOtherProfileActionCell.identifier)
        self.tableView.register(CKAccountProfileInfoCell.nib, forCellReuseIdentifier: CKAccountProfileInfoCell.identifier)
        self.tableView.register(CKAccountProfileJobCell.nib, forCellReuseIdentifier: CKAccountProfileJobCell.identifier)
        self.tableView.register(CKAccountProfileTimeCell.nib, forCellReuseIdentifier: CKAccountProfileTimeCell.identifier)
        self.tableView.register(CKAccountProfileEmailCell.nib, forCellReuseIdentifier: CKAccountProfileEmailCell.identifier)
        self.tableView.allowsSelection = false
        
        // Setup back button item
        let backItemButton = UIBarButtonItem.init(image: UIImage(named: "ic_room_member_arrow"), style: .plain, target: self, action: #selector(clickedOnBackButton(_:)))
        
        // assign back button
        self.navigationItem.leftBarButtonItem = backItemButton
    }
    
    private func cellForAvatarPersonal(atIndexPath indexPath: IndexPath) -> CKAccountProfileAvatarCell {
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: CKAccountProfileAvatarCell.identifier, for: indexPath) as? CKAccountProfileAvatarCell {
            
            let mxMember = self.mxNumber[indexPath.row]
            
            cell.nameLabel.text = mxMember.displayname
            
            if let avtURL = self.mainSession.matrixRestClient.url(ofContent: mxMember.avatarUrl ) {
                cell.setAvatarImageUrl(urlString: avtURL, previewImage: nil)
            } else {
                cell.avaImage.image = AvatarGenerator.generateAvatar(forText: mxMember.userId)
            }
            
            //status
            let session = AppDelegate.the()?.mxSessions.first as? MXSession
            if let myUser = session?.myUser {
                switch myUser.presence {
                case MXPresenceOnline:
                    cell.settingStatus(online: true)
                default:
                    cell.settingStatus(online: false)
                }
            }
            return cell
        }
        return CKAccountProfileAvatarCell()
    }
    
    private func cellForAction(atIndexPath indexPath: IndexPath) -> CKOtherProfileActionCell {
        
        // dequeue cell
        if let cell = tableView.dequeueReusableCell(
            withIdentifier: CKOtherProfileActionCell.identifier,
            for: indexPath) as? CKOtherProfileActionCell {
            
            return cell
        }
        return CKOtherProfileActionCell()
    }
    
    private func cellForInfoPersonal(atIndexPath indexPath: IndexPath) -> CKAccountProfileInfoCell {
        
        if let cell = tableView.dequeueReusableCell(
            withIdentifier: CKAccountProfileInfoCell.identifier,
            for: indexPath) as? CKAccountProfileInfoCell {
            
            
            // Title
            cell.titleLabel.font = CKAppTheme.mainLightAppFont(size: 17)
            cell.titleLabel.textColor = #colorLiteral(red: 0.4352941176, green: 0.431372549, blue: 0.4509803922, alpha: 1)
            cell.titleLabel.text = "Display name"
            
            // display name
            let mxMember = self.mxNumber[indexPath.row]
            cell.contentLabel.text = mxMember.displayname
            
            return cell
        }
        return CKAccountProfileInfoCell()
    }
    
    
    private func cellForJobPersonal(atIndexPath indexPath: IndexPath) -> CKAccountProfileJobCell {
        
        // dequeue cell
        let cell = tableView.dequeueReusableCell(
            withIdentifier: CKAccountProfileJobCell.identifier,
            for: indexPath) as! CKAccountProfileJobCell
        cell.titleLabel.font = CKAppTheme.mainLightAppFont(size: 17)
        cell.titleLabel.textColor = #colorLiteral(red: 0.4352941176, green: 0.431372549, blue: 0.4509803922, alpha: 1)
        return cell
    }
    
    private func cellForTime(atIndexPath indexPath: IndexPath) -> CKAccountProfileTimeCell {
        
        // dequeue cell
        let cell = tableView.dequeueReusableCell(
            withIdentifier: CKAccountProfileTimeCell.identifier,
            for: indexPath) as! CKAccountProfileTimeCell
        
        cell.titleLabel.font = CKAppTheme.mainLightAppFont(size: 17)
        cell.titleLabel.textColor = #colorLiteral(red: 0.4352941176, green: 0.431372549, blue: 0.4509803922, alpha: 1)
        return cell
    }
    
    private func cellForEmailPersonal(atIndexPath indexPath: IndexPath) -> CKAccountProfileEmailCell {
        
        // dequeue cell
        let cell = tableView.dequeueReusableCell(
            withIdentifier: CKAccountProfileEmailCell.identifier,
            for: indexPath) as! CKAccountProfileEmailCell
        
        cell.titleLabel.font = CKAppTheme.mainLightAppFont(size: 17)
        cell.titleLabel.textColor = #colorLiteral(red: 0.4352941176, green: 0.431372549, blue: 0.4509803922, alpha: 1)
        cell.contentLabel.textColor = CKColor.Text.lightBlueText
        return cell
    }
    
    
    
    
    // MARK: - ACTION
    
    @objc func clickedOnBackButton(_ sender: Any?) {
        self.dismiss(animated: true, completion: nil)
    }
    
    private func titleForHeader(atSection section: Int) -> String {
        guard let section = Section(rawValue: section) else { return ""}
        
        switch section {
        case .avatar:
            return ""
        case .action:
            return ""
        case .detail:
            return ""
        }
    }
}

// MARK: - UITableViewDelegate

extension CKOtherProfileViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let section = Section(rawValue: indexPath.section) else { return 0}
        switch section {
        case .avatar:
            return 250
            
        default:
            return 60
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView.init()
        view.backgroundColor = UIColor.white
        return view
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView.init()
        view.backgroundColor = UIColor.white
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10
    }
    
}

// MARK: - UITableViewDataSource

extension CKOtherProfileViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // sure to work
        guard let section = Section(rawValue: section) else { return 0 }
        
        // number rows in case
        switch section {
        case .avatar: return 1
        case .action: return 1
        case .detail: return 4
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // sure to work
        guard let section = Section(rawValue: indexPath.section) else { return CKAccountProfileBaseCell() }
        
        switch section {
        case .avatar:
            
            // account profile avatar cell
            return cellForAvatarPersonal(atIndexPath: indexPath)
        case .action:
            
            // account profile action cell
            return cellForAction(atIndexPath: indexPath)
        case .detail:
            if indexPath.row == 0 {
                // account profile info cell
                return cellForInfoPersonal(atIndexPath: indexPath)
            }
            
            // account profile info cell
            if indexPath.row == 1 {
                return cellForJobPersonal(atIndexPath: indexPath)
            }
            
            // account profile info cell
            if indexPath.row == 2 {
                return cellForTime(atIndexPath: indexPath)
            }
            
            // account profile info cell
            if indexPath.row == 3 {
                return cellForEmailPersonal(atIndexPath: indexPath)
            }
        }
        return UITableViewCell()
    }
}


