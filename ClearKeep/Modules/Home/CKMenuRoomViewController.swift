//
//  ShowMenuOptionVC.swift
//  Riot
//
//  Created by Vuong Le on 2/20/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

internal enum CKMenuTableViewType: Int {
    case recent
    case message
}

internal enum CKMenuRoomCellType {
    case unMute
    case mute
    case removeFromFavourite
    case addToFavourite
    case setting
    case leave
    case edit
    case delete
    case quote
    case copy
    case share
    case selectAll
    case showDetails
    
    // title
    func title() -> String {
        switch self {
        case .unMute:
            return "Turn on room notification"
        case .mute:
            return "Turn off room notification"
        case .removeFromFavourite:
            return "Remove from favourite"
        case .addToFavourite:
            return "Add to favourite"
        case .setting:
            return "Setting"
        case .leave:
            return "Leave"
        case .edit:
            return "Edit"
        case .delete:
            return "Delete"
        case .quote:
            return "Quote"
        case .copy:
            return "Copy"
        case .share:
            return "Share"
        case .selectAll:
            return "Select all"
        case .showDetails:
            return "Show details"
            
        }
    }
    
    // icon
    func icon() -> String {
        switch self {
            
        // Recent menu
        case .unMute:
            return "ic_room_bell_on"
        case .mute:
            return "ic_room_bell_off"
        case .removeFromFavourite:
            return "ic_room_unfavourite"
        case .addToFavourite:
            return "ic_room_favourite"
        case .setting:
            return "ic_room_settings"
        case .leave:
            return "ic_leave_room"
            
        // Message menu
        case .edit:
            return "ic_msg_edit"
        case .delete:
            return "ic_msg_delete"
        case .quote:
            return "ic_msg_quote"
        case .copy:
            return "ic_msg_copy"
        case .share:
            return "ic_msg_share"
        case .selectAll:
            return "ic_msg_select_all"
        case .showDetails:
            return "ic_msg_detail"
        }
        
    }
}

// MARK: - CKRoomMenuViewController

final class CKMenuRoomViewController: UIViewController {
    
    // MARK: - OUTLET
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var reactioncontainerView: UIView!
    @IBOutlet weak var reactioncontrainerHeightConstraint: NSLayoutConstraint!

    // MARK: - PROPERTY

    internal var datasourceTableView: [CKMenuRoomCellType] = []
    internal var callBackCKRecentListVC: ((_ result: CKMenuRoomCellType) -> Void)?
    internal var mute: CKMenuRoomCellType = .unMute
    internal var favourite: CKMenuRoomCellType = .removeFromFavourite
    internal var menuType: CKMenuTableViewType = .recent

    private let disposeBag = DisposeBag()

    // MARK: - OVERRIDE
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.estimatedRowHeight = 50
        self.tableView.separatorStyle = .singleLine
        self.tableView.bounces = false

        tableView.register(
            UINib.init(nibName: "CKAlertSettingRoomCell", bundle: nil),
            forCellReuseIdentifier: "CKAlertSettingRoomCell")

        bindingTheme()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if menuType == .recent {
            reactioncontainerView.isHidden = true
            reactioncontrainerHeightConstraint.constant = 0
            datasourceTableView = [mute, favourite, .setting, .leave]
        } else {
            reactioncontainerView.isHidden = false
            reactioncontrainerHeightConstraint.constant = 40
            datasourceTableView = [.copy, .edit, .quote, .share, .selectAll, .showDetails]
        }
        self.tableView.reloadData()
    }

    // MARK: - PRIVATE

    private func bindingTheme() {
        // Binding navigation bar color
        themeService.attrsStream.subscribe(onNext: { [weak self] (theme) in
            self?.tableView.reloadData()
        }).disposed(by: disposeBag)

        themeService.rx
            .bind({ $0.primaryBgColor }, to: view.rx.backgroundColor, tableView.rx.backgroundColor)
            .disposed(by: disposeBag)
    }

    @IBAction func buttonMoreReactionDidPress(_ sender: UIButton) {
    }

    // MARK: - PUBLIC
}

extension CKMenuRoomViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datasourceTableView.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "CKAlertSettingRoomCell", for: indexPath)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let data = datasourceTableView[indexPath.row]
        if let cell = cell as? CKAlertSettingRoomCell {
            cell.imgCell.image = UIImage.init(named: data.icon())?.withRenderingMode(.alwaysTemplate)
            cell.lblTitle.text = data.title()

            cell.lblTitle.textColor = themeService.attrs.primaryTextColor
            cell.imgCell.tintColor = themeService.attrs.primaryTextColor
            cell.backgroundColor = themeService.attrs.primaryBgColor
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: CGRect.zero)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let data = datasourceTableView[indexPath.row]
        switch data {
        case .unMute:
            self.callBackCKRecentListVC?(.unMute)
        case .mute:
            self.callBackCKRecentListVC?(.mute)
        case .removeFromFavourite:
            self.callBackCKRecentListVC?(.removeFromFavourite)
        case .addToFavourite:
            self.callBackCKRecentListVC?(.addToFavourite)
        case .setting:
            self.callBackCKRecentListVC?(.setting)
        case .leave:
            self.callBackCKRecentListVC?(.leave)
        case .edit:
            self.callBackCKRecentListVC?(.edit)
        case .delete:
            self.callBackCKRecentListVC?(.delete)
        case .quote:
            self.callBackCKRecentListVC?(.quote)
        case .copy:
            self.callBackCKRecentListVC?(.copy)
        case .share:
            self.callBackCKRecentListVC?(.share)
        case .selectAll:
            self.callBackCKRecentListVC?(.selectAll)
        case .showDetails:
            self.callBackCKRecentListVC?(.showDetails)
        }
        
        tableView.reloadData()
    }
    
}
