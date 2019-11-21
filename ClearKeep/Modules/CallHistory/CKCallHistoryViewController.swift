//
//  CKCallHistoryViewController.swift
//  Riot
//
//  Created by ReasonLeveing on 11/19/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

@objc class CKCallHistoryViewController: MXKViewController {
    
    private let disposeBag = DisposeBag()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        tableView.register(CKHeaderCallHistoryView.nib, forHeaderFooterViewReuseIdentifier: CKHeaderCallHistoryView.identifier)
//        tableView.register(CKCallHistoryCell.nib, forCellReuseIdentifier: CKCallHistoryCell.identifier)
        
//        bindingTheme()
        
//        let dataSource = CKCallHistoryDataSource()
//        dataSource.getListCallHistory()

    }
    
    private func bindingTheme() {
        // Binding navigation bar color
        themeService.attrsStream.subscribe(onNext: { [weak self] (theme) in
            self?.defaultBarTintColor = themeService.attrs.navBarBgColor
            self?.barTitleColor = themeService.attrs.primaryTextColor
        }).disposed(by: disposeBag)

        themeService.rx
            .bind({ $0.primaryBgColor }, to: view.rx.backgroundColor, tableView.rx.backgroundColor)
            .disposed(by: disposeBag)
    }
}


// MARK: UITableViewDelegate
extension CKCallHistoryViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: CKHeaderCallHistoryView.identifier) as? CKHeaderCallHistoryView else {
            return nil
        }
        
        return headerView
    }
}


// MARK: UITableViewDataSource
extension CKCallHistoryViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 100
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CKCallHistoryCell.identifier,
                                                       for: indexPath) as? CKCallHistoryCell else {
            return UITableViewCell()
        }
        
        cell.textLabel?.text = "\(indexPath.row)"
        
        return cell
    }
    
}
