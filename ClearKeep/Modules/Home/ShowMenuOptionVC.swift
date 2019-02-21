//
//  ShowMenuOptionVC.swift
//  Riot
//
//  Created by Vuong Le on 2/20/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit
enum typeCellShowMenu {
    case unMute
    case mute
    case removeFromFavourite
    case addToFavourite
    case setting
    case cancel

    func title() -> String {
        switch self {
        case .unMute:
            return "UnMute"
        case .mute:
            return "UnMute"
        case .removeFromFavourite:
            return "Remove from favourite"
        case .addToFavourite:
            return "Add to favourite"
        case .setting:
            return "Setting"
        case .cancel:
            return "Cancel"
        }
    }
    
    func icon() -> String {
        switch self {
        case .unMute:
            return "notifications"
        case .mute:
            return "notificationsOff"
        case .removeFromFavourite:
            return "favouriteOff"
        case .addToFavourite:
            return "favourite"
        case .setting:
            return "settings_icon"
        case .cancel:
            return ""
        }
    }
}
class ShowMenuOptionVC: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    var datasourceTableView: [typeCellShowMenu] = []
    var callBackCKRecentListVC: ((_ result:typeCellShowMenu) -> Void)?
    var mute: typeCellShowMenu = .unMute
    var favourite: typeCellShowMenu = .removeFromFavourite
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        self.tableView.estimatedRowHeight = 50
        tableView.register(UINib.init(nibName: "CKAlertSettingRoomCell", bundle: nil), forCellReuseIdentifier: "CKAlertSettingRoomCell")
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        datasourceTableView = [mute, favourite, .setting, .cancel]
    }

}

extension ShowMenuOptionVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datasourceTableView.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let data = datasourceTableView[indexPath.row]
        if data == .cancel {
            return 60
        } else {
            return 44
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let data = datasourceTableView[indexPath.row]
        if data == .cancel {
            let cell = UITableViewCell()
            let lbl = UILabel.init(frame: CGRect.init(x: 40, y: 16, width: self.view.bounds.width - 80, height: 44))
            lbl.text = data.title()
            lbl.font = UIFont.boldSystemFont(ofSize: 16)
            lbl.textColor = .red
            lbl.textAlignment = .center
            cell.addSubview(lbl)
            lbl.borderWidth = 2
            lbl.borderColor = UIColor.gray
            lbl.cornerRadius = 5
            return cell
        } else {
            return tableView.dequeueReusableCell(withIdentifier: "CKAlertSettingRoomCell", for: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let data = datasourceTableView[indexPath.row]
        if data != .cancel {
            if let cell = cell as? CKAlertSettingRoomCell {
                cell.imgCell.image = UIImage.init(named: data.icon())
                cell.lblTitle.text = data.title()
            }
        }
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
        case .cancel:
            self.callBackCKRecentListVC?(.cancel)
        }
        
        tableView.reloadData()
    }
    
}
