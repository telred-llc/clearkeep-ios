//
//  CKFavouriteViewController.swift
//  Riot
//
//  Created by Pham Hoa on 2/1/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

class CKFavouriteViewController: CKRecentListViewController {

    // MARK: Properties

    var recentsDataSource: RecentsDataSource?
    var missedDiscussionsCount: UInt {
        get {
            return self.recentsDataSource?.missedFavouriteDiscussionsCount ?? 0
        }
    }

    // MARK: LifeCycle
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let recentsDataSource = self.recentsDataSource {
            recentsDataSource.areSectionsShrinkable = false
            recentsDataSource.setDelegate(self, andRecentsDataSourceMode: RecentsDataSourceModeFavourites)
        }
        
        // Observe server sync at room data source level too
        NotificationCenter.default.addObserver(self, selector: #selector(onMatrixSessionChange), name: NSNotification.Name(rawValue: kMXKRoomDataSourceSyncStatusChanged), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: kMXKRoomDataSourceSyncStatusChanged), object: nil)
    } 

    @objc public func displayList(_ aRecentsDataSource: MXKRecentsDataSource!) {
        
        // sure this one
        guard let recentsDataSource = aRecentsDataSource else {
            return
        }

        // Cancel registration on existing dataSource if any
        if self.recentsDataSource != nil {
            self.recentsDataSource!.delegate = nil
            
            // Remove associated matrix sessions
            let mxSessions = self.mxSessions as? [MXSession]
            mxSessions.flatMap({ return $0 })?.forEach({ (mxSession) in
                self.removeMatrixSession(mxSession)
            })
        }
        
        self.recentsDataSource = recentsDataSource as? RecentsDataSource
        self.recentsDataSource?.delegate = self
        
        // Report all matrix sessions at view controller level to update UI according to sessions state
        let mxSessions = recentsDataSource.mxSessions as? [MXSession]
        mxSessions.flatMap({ return $0 })?.forEach({ (mxSession) in
            self.addMatrixSession(mxSession)
        })
    }

    @objc override func onMatrixSessionChange() {
        super.onMatrixSessionChange()
        
        let mxSessions = self.mxSessions as? [MXSession]
        mxSessions.flatMap({ return $0 })?.forEach({ (mxSession) in
            if MXKRoomDataSourceManager.sharedManager(forMatrixSession: mxSession)?.isServerSyncInProgress == true {
                // sync is in progress for at least one data source, keep running the loading wheel
                self.activityIndicator?.startAnimating()
                return
            }
        })
    }

    @objc public func scrollToNextRoomWithMissedNotifications() {
        // TODO
    }
}

extension CKFavouriteViewController: MXKDataSourceDelegate {
    
    func cellViewClass(for cellData: MXKCellData!) -> MXKCellRendering.Type! {
        return CKRecentItemTableViewCell.self
    }
    
    func cellReuseIdentifier(for cellData: MXKCellData!) -> String! {
        return CKRecentItemTableViewCell.defaultReuseIdentifier()
    }
    
    @objc public func dataSource(_ dataSource: MXKDataSource?, didCellChange changes: Any?) {
        self.reloadDataSource()
        
        // reflect Badge
        AppDelegate.the()?.masterTabBarController.reflectingBadges() 
    }
    
    func dataSource(_ dataSource: MXKDataSource!, didAddMatrixSession mxSession: MXSession!) {
        self.addMatrixSession(mxSession)
    }
    
    func dataSource(_ dataSource: MXKDataSource!, didRemoveMatrixSession mxSession: MXSession!) {
        self.removeMatrixSession(mxSession)
    }
    
    private func reloadDataSource() {
//        if var favouritesArray = self.recentsDataSource?.favoriteCellDataArray as? [MXKRecentCellData] {
//            favouritesArray.reverse()
//            self.reloadData(rooms: [favouritesArray])
//        } else {
//            self.reloadData(rooms: [])
//        }
        
        var rooms: [[MXKRecentCellData]] = []
        var roomsArray: [MXKRecentCellData] = []
        var peopleArray: [MXKRecentCellData] = []

        if let favouritesArray = self.recentsDataSource?.favoriteCellDataArray as? [MXKRecentCellData] {
            for favourite in favouritesArray.reversed() {
                if favourite.roomSummary.isDirect {
                    peopleArray.insert(favourite, at: 0)
                } else {
                    roomsArray.insert(favourite, at: 0)
                }
            }
        }
        rooms.append(roomsArray)
        rooms.append(peopleArray)
//
//        if var roomsArray = self.recentsDataSource?.conversationCellDataArray as? [MXKRecentCellData] {
//            if let invitesArray = self.recentsDataSource?.invitesCellDataArray as? [MXKRecentCellData] {
//                for invite in invitesArray.reversed() {
//                    if invite.roomSummary.isDirect == false {
//                        roomsArray.insert(invite, at: 0)
//                    }
//                }
//            }
//            rooms.append(roomsArray)
//        } else {
//            rooms.append([])
//        }
//
//        if var peopleArray = self.recentsDataSource?.peopleCellDataArray as? [MXKRecentCellData] {
//            if let invitesArray = self.recentsDataSource?.invitesCellDataArray as? [MXKRecentCellData] {
//                for invite in invitesArray.reversed() {
//                    if invite.roomSummary.isDirect == true {
//                        peopleArray.insert(invite, at: 0)
//                    }
//                }
//            }
//            rooms.append(peopleArray)
//        } else {
//            rooms.append([])
//        }
//        self.missedDiscussionsCount = rooms.reduce(0, { $0 + $1.filter({ $0.roomSummary.membership == MXMembership.invite || $0.hasUnread || $0.notificationCount > 0 }).count })
        self.reloadData(rooms: rooms)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let roomSettingsVC = segue.destination as? CKRoomSettingsViewController, let roomCellData = sender as? MXKRecentCellData {
            roomSettingsVC.initWith(roomCellData.roomSummary.mxSession, andRoomId: roomCellData.roomSummary.roomId)
        }
    }
}

