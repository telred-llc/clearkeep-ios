//
//  CKRoomFilesViewController.swift
//  Riot
//
//  Created by Developer Super on 3/25/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit
import MatrixKit

final class CKRoomFilesViewController: MXKRoomViewController {
    
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBubblesTableView()
        bindingTheme()
    }
    
    override func finalizeInit() {
        super.finalizeInit()
        self.enableBarTintColorStatusChange = false
        //self.rageShakeManager = RageShakeManager.sharedManager() as? MXKResponderRageShaking
    }
    
    private func setupBubblesTableView() {
        self.setRoomInputToolbarViewClass(nil)
        self.setRoomActivitiesViewClass(nil)
       
        // Custom attackmentViewController
        self.setAttachmentsViewerClass(CKAttachmentsViewController.self)
        self.bubblesTableView.register(FilesSearchTableViewCell.self, forCellReuseIdentifier: FilesSearchTableViewCell.defaultReuseIdentifier())
        
        self.bubblesTableView.separatorStyle = .singleLine
        
        // Hide line separators of empty cells
        self.bubblesTableView.tableFooterView = UIView()
        
        self.setNavBarButtons()
        
        // Update the inputToolBar height (This will trigger a layout refresh)
        UIView.animate(withDuration: 0) {
            self.roomInputToolbarView(self.inputToolbarView, heightDidChanged: 0, completion: nil)
            self.view.layoutIfNeeded()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = "Files"
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.delegate = nil
        super.viewWillDisappear(animated)
    }
    
    override func didMove(toParentViewController parent: UIViewController?) {
        super.didMove(toParentViewController: parent)
        setNavBarButtons()
    }

    private func bindingTheme() {
        // Binding navigation bar color
        themeService.attrsStream.subscribe(onNext: { [weak self] (theme) in
            self?.defaultBarTintColor = themeService.attrs.primaryBgColor
            self?.barTitleColor = themeService.attrs.primaryTextColor
            if self?.bubblesTableView.dataSource != nil {
                self?.bubblesTableView.reloadData()
            }
            self?.activityIndicator?.backgroundColor = themeService.attrs.overlayColor
        }).disposed(by: disposeBag)

        themeService.rx
            .bind({ $0.secondBgColor }, to: view.rx.backgroundColor, bubblesTableView.rx.backgroundColor)
            .disposed(by: disposeBag)
    }

    private func setNavBarButtons() {
        let topViewController = self.parent ?? self
        topViewController.navigationItem.rightBarButtonItem = nil
        topViewController.navigationItem.leftBarButtonItem = nil
    }

    // MARK: - MXKDataSourceDelegate
    
    override func cellViewClass(for cellData: MXKCellData!) -> MXKCellRendering.Type! {
        // Sanity check
        if let bubbleData = cellData as? MXKRoomBubbleCellDataStoring, bubbleData.attachment != nil {
            return FilesSearchTableViewCell.self
        }
        
        return nil
    }
    
    override func cellReuseIdentifier(for cellData: MXKCellData!) -> String! {
        if let classType: AnyClass = self.cellViewClass(for: cellData) {
            if classType == FilesSearchTableViewCell.self {
                return classType.defaultReuseIdentifier()
            }
            return nil
        }

        return nil
    }
    
    // MARK: - UITableView delegate

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = kRiotPrimaryBgColor
        if kRiotSelectedBgColor != nil {
            cell.selectedBackgroundView = UIView()
            cell.selectedBackgroundView?.backgroundColor = kRiotSelectedBgColor
        } else {
            if tableView.style == .plain {
                cell.selectedBackgroundView = nil
            } else {
                cell.selectedBackgroundView?.backgroundColor = nil
            }
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == self.bubblesTableView, let cell = tableView.cellForRow(at: indexPath) as? FilesSearchTableViewCell {
            self.showAttachment(in: cell)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}
