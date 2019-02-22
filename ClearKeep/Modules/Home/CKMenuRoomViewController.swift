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

    // MARK: - OVERRIDE
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        self.tableView.estimatedRowHeight = 50
        tableView.register(
            UINib.init(nibName: "CKAlertSettingRoomCell", bundle: nil),
            forCellReuseIdentifier: "CKAlertSettingRoomCell")
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        datasourceTableView = [mute, favourite, .setting]
    }

    // MARK: - PRIVATE
    
    // MARK: - PUBLIC

}

extension CKMenuRoomViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datasourceTableView.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "CKAlertSettingRoomCell", for: indexPath)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let data = datasourceTableView[indexPath.row]
        if let cell = cell as? CKAlertSettingRoomCell {
            cell.imgCell.image = UIImage.init(named: data.icon())
            cell.lblTitle.text = data.title()
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
        }
        
        tableView.reloadData()
    }
    
}
