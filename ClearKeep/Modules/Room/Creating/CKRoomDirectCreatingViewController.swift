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
    }
    
    // MARK: - PRIVATE
    
    private func cellForAction(atIndexPath indexPath: IndexPath) -> CKRoomDirectCreatingActionCell {
        if let cell = tableView.dequeueReusableCell(
            withIdentifier: CKRoomDirectCreatingActionCell.identifier,
            for: indexPath) as? CKRoomDirectCreatingActionCell {
            return cell
        }
        return CKRoomDirectCreatingActionCell()
    }

    private func cellForSuggested(atIndexPath indexPath: IndexPath) -> CKRoomDirectCreatingSuggestedCell {
        
        if let cell = tableView.dequeueReusableCell(
            withIdentifier: CKRoomDirectCreatingSuggestedCell.identifier,
            for: indexPath) as? CKRoomDirectCreatingSuggestedCell {
            return cell
        }
        return CKRoomDirectCreatingSuggestedCell()
    }
    
    private func titleForHeader(atSection section: Int) -> String {
        guard let s = Section(rawValue: section) else { return ""}
        
        switch s {
        case .action:
            return ""
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
}

extension CKRoomDirectCreatingViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let s = Section(rawValue: section) else { return 0}
        
        switch s {
        case .action:
            return 1
        case .suggested:
            return 3
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return CKRoomBaseCell()
    }
    
    
}
