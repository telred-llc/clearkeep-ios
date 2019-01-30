//
//  CKContactListViewController.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/28/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKContactListViewController: MXKViewController {
    
    // MARK: - OUTLET
    
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - ENUM
    
    private enum Section: Int {
        case search = 0
        case matrix = 1
        case local = 2
        
        static func count() -> Int {
            return 3
        }
    }
    
    // MARK: - PROPERTY
    
    /**
     Original data sources
     */
    private var originalMatrixSource = [MXKContact]()
    private var originalLocalSource = [MXKContact]()
    
    /**
     Filtered data sources
     */
    private var filteredLocalSource = [MXKContact]()
    private var filteredMatrixSource = [MXKContact]()
    
    // MARK: - CLASS
    
    public class func nib() -> UINib? {
        return UINib.init(
            nibName: CKContactListViewController.nibName,
            bundle: Bundle(for: self))
    }
    
    // MARK: - OVERRIDE
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // load from xib
        if let nib = CKContactListViewController.nib() {
            nib.instantiate(withOwner: self, options: nil)
            self.tableView.reloadData()
            self.registerCells()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    // MARK: - OBJC
    
    @objc public func displayList(_ recentsDataSource: MXKRecentsDataSource) {
        // TODO
    }
    
    @objc public func scrollToNextRoomWithMissedNotifications() {
        // TODO
    }
}

// MARK: - PRIVATE

extension CKContactListViewController {
    
    /**
     Get a title for the header
     */
    private func titleForHeader(atSection section: Int) -> String {
        guard let s = Section(rawValue: section) else { return ""}
        
        switch s {
        case .search:
            return ""
        case .matrix:
            return "MATRIX"
        case .local:
            return "LOCAL"
        }
    }
    
    /**
     Register table view cell
     */
    private func registerCells() {
        self.tableView.register(CKContactListSearchCell.nib, forCellReuseIdentifier: CKContactListSearchCell.identifier)
        self.tableView.register(CKContactListMatrixCell.nib, forCellReuseIdentifier: CKContactListMatrixCell.identifier)
        self.tableView.register(CKContactListLocalCell.nib, forCellReuseIdentifier: CKContactListLocalCell.identifier)
    }
    
    /**
     Cell for search
     */
    private func cellForSearch(_ indexPath: IndexPath) -> CKContactListSearchCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: CKContactListSearchCell.identifier, for: indexPath) as! CKContactListSearchCell
        return cell
    }
    
    /**
     Cell for matrix contact
     */
    private func cellForMatrix(_ indexPath: IndexPath) -> CKContactListMatrixCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: CKContactListMatrixCell.identifier, for: indexPath) as! CKContactListMatrixCell
        return cell
    }
    
    /**
     Cell for local contact
     */
    private func cellForLocal(_ indexPath: IndexPath) -> CKContactListLocalCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: CKContactListLocalCell.identifier, for: indexPath) as! CKContactListLocalCell
        return cell
    }
}

// MARK: - UITableViewDelegate

extension CKContactListViewController: UITableViewDelegate {
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
            view.title = self.titleForHeader(atSection: section)
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
            return CKLayoutSize.Table.header1px
        default:
            return CKLayoutSize.Table.header40px
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CKLayoutSize.Table.footer1px
    }
}

// MARK: - UITableViewDataSource

extension CKContactListViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let s = Section(rawValue: section) else { return 0}
        
        switch s {
        case .search:
            return 1
        case .matrix:
            return self.filteredMatrixSource.count
        case .local:
            return self.filteredLocalSource.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let s = Section(rawValue: section) else { return 0}
        
        switch s {
        case .search:
            return cellForSearch(indexPath)
        case .matrix:
            return cellForMatrix(indexPath)
        case .local:
            return cellForLocal(indexPath)
        }
    }
}
