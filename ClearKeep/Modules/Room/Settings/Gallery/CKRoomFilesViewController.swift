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
    
    private var kRiotDesignValuesDidChangeThemeNotificationObserver: Any?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBubblesTableView()
        setNavigationBarTitle()
        // Do any additional setup after loading the view.
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
        
        kRiotDesignValuesDidChangeThemeNotificationObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.riotDesignValuesDidChangeTheme, object: nil, queue: OperationQueue.main, using: { [weak self] notif in
            if let weakSelf = self {
                weakSelf.userInterfaceThemeDidChange()
            }
        })
        
        self.userInterfaceThemeDidChange()
    }
    
    func userInterfaceThemeDidChange() {
        self.defaultBarTintColor = kRiotSecondaryBgColor
        self.barTitleColor = kRiotPrimaryTextColor
        self.activityIndicator.backgroundColor = kRiotOverlayColor
        
        // Check the table view style to select its bg color.
        self.bubblesTableView.backgroundColor = self.bubblesTableView.style == .plain ? kRiotPrimaryBgColor : kRiotSecondaryBgColor
        self.view.backgroundColor = self.bubblesTableView.backgroundColor
        if self.bubblesTableView.dataSource != nil {
            self.bubblesTableView.reloadData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.delegate = nil
        super.viewDidAppear(animated)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
         return kRiotDesignStatusBarStyle
    }
    
    override func destroy() {
        if (kRiotDesignValuesDidChangeThemeNotificationObserver != nil) {
            NotificationCenter.default.removeObserver(kRiotDesignValuesDidChangeThemeNotificationObserver!)
            kRiotDesignValuesDidChangeThemeNotificationObserver = nil
        }
        super.destroy()
    }
    
    override func didMove(toParentViewController parent: UIViewController?) {
        super.didMove(toParentViewController: parent)
        setNavBarButtons()
    }
    
    private func setNavBarButtons() {
        let topViewController = self.parent ?? self
        topViewController.navigationItem.rightBarButtonItem = nil
        topViewController.navigationItem.leftBarButtonItem = nil
    }
    
    private func setNavigationBarTitle() {
        let titleLabel = UILabel()
        titleLabel.text = "Files"
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.sizeToFit()
        self.navigationItem.titleView = titleLabel
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
