//
//  CKRoomDirectCreatingViewController.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/21/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKRoomDirectCreatingViewController: MXKViewController {
    
    // MARK: - OUTLET
    
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - ENUM
    
    private enum Section: Int {
        case action = 0
        case suggested = 1
        
        static func count() -> Int {
            return 2
        }
    }
    
    // MARK: - CLASS M
    
    class func instance() -> CKRoomDirectCreatingViewController {
        let instance = CKRoomDirectCreatingViewController(nibName: self.nibName, bundle: nil)
        return instance
    }
    
    class func instanceForNavigationController(completion: ((_ instance: CKRoomDirectCreatingViewController) -> Void)?) -> UINavigationController {
        let vc = self.instance()
        completion?(vc)
        return UINavigationController.init(rootViewController: vc)
    }
    
    // MARK: - OVERRIDE
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.allowsSelection = false
        self.tableView.register(CKRoomDirectCreatingActionCell.nib, forCellReuseIdentifier: CKRoomDirectCreatingActionCell.identifier)
        self.tableView.register(CKRoomDirectCreatingSuggestedCell.nib, forCellReuseIdentifier: CKRoomDirectCreatingSuggestedCell.identifier)
        
        // Setup back button item
        let backItemButton = UIBarButtonItem.init(
            title: "Back",
            style: .plain, target: self,
            action: #selector(clickedOnBackButton(_:)))
        
        self.navigationItem.leftBarButtonItem = backItemButton
        self.navigationItem.title = "New Chat"
    }
    
    // MARK: - ACTION
    
    @objc func clickedOnBackButton(_ sender: Any?) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - PRIVATE
    
    private func cellForAction(atIndexPath indexPath: IndexPath) -> CKRoomDirectCreatingActionCell {
        if let cell = tableView.dequeueReusableCell(
            withIdentifier: CKRoomDirectCreatingActionCell.identifier,
            for: indexPath) as? CKRoomDirectCreatingActionCell {
            
            // action
            cell.newGroupHandler = {
                
                if let nvc = self.navigationController {
                    let vc = CKRoomCreatingViewController.instance()
                    vc.importSession(self.mxSessions)
                    nvc.pushViewController(vc, animated: true)
                    
                } else {
                    let nvc = CKRoomCreatingViewController.instanceForNavigationController(completion: { (vc: CKRoomCreatingViewController) in
                        vc.importSession(self.mxSessions)
                    })
                    self.present(nvc, animated: true, completion: nil)
                }
            }
            
            return cell
        }
        return CKRoomDirectCreatingActionCell()
    }

    private func cellForSuggested(atIndexPath indexPath: IndexPath) -> CKRoomDirectCreatingSuggestedCell {
        
        if let cell = tableView.dequeueReusableCell(
            withIdentifier: CKRoomDirectCreatingSuggestedCell.identifier,
            for: indexPath) as? CKRoomDirectCreatingSuggestedCell {
            
            if let contact = MXKContactManager.shared()?.matrixContacts[indexPath.row] as? MXKContact {
                
                // display name
                cell.suggesteeLabel.text = contact.displayName
                
                // avatar
                if let avtURL = self.mainSession.matrixRestClient.url(ofContent: contact.matrixAvatarURL) {
                    cell.setAvatarImageUrl(urlString: avtURL, previewImage: nil)
                } else {
                    cell.photoView.image = AvatarGenerator.generateAvatar(forText: contact.displayName)
                }
            }
            
            return cell
        }
        return CKRoomDirectCreatingSuggestedCell()
    }
    
    private func titleForHeader(atSection section: Int) -> String {
        guard let s = Section(rawValue: section) else { return ""}
        
        switch s {
        case .action:
            return "PROBABLY YOU WANT"
        case .suggested:
            return "SUGGESTED"
        }
    }

}

extension CKRoomDirectCreatingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let s = Section(rawValue: indexPath.section) else { return 0}
        
        switch s {
        case .action:
            return 80
        case .suggested:
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
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
}

extension CKRoomDirectCreatingViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let s = Section(rawValue: section) else { return 0}
        
        switch s {
        case .action:
            return 1
        case .suggested:
            if let ctxs = MXKContactManager.shared() {
                return ctxs.matrixContacts != nil ? ctxs.matrixContacts.count : 0
            }
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let s = Section(rawValue: indexPath.section) else { return CKRoomCreatingBaseCell()}
        
        switch s {
        case .action:
            return self.cellForAction(atIndexPath: indexPath)
        case .suggested:
            return self.cellForSuggested(atIndexPath: indexPath)
        }
    }
    
    
}
