//
//  ShowMenuOptionVC.swift
//  Riot
//
//  Created by Vuong Le on 2/20/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

internal enum CKMenuRoomCellType {
    case unMute
    case mute
    case removeFromFavourite
    case addToFavourite
    case setting
    case leave

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
        }
    }
    
    // icon
    func icon() -> String {
        switch self {
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
        }
    }
}

// MARK: - CKRoomMenuViewController

final class CKMenuRoomViewController: UIViewController {
    
    // MARK: - OUTLET
    
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - PROPERTY
    
    internal var datasourceTableView: [CKMenuRoomCellType] = []
    internal var callBackCKRecentListVC: ((_ result: CKMenuRoomCellType) -> Void)?
    internal var mute: CKMenuRoomCellType = .unMute
    internal var favourite: CKMenuRoomCellType = .removeFromFavourite

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
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        datasourceTableView = [mute, favourite, .setting, .leave]
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
        }
        
        tableView.reloadData()
    }
    
}
