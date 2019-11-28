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
    
    @objc public class func objInstance() -> Self {
        return self.instance()
    }
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.tableFooterView = UIView()
        }
    }
    
    private var listCallHistory: [CallHistoryModel] = [] {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    var dataSource: CKCallHistoryDataSource?
    
    lazy var alertError = MXKErrorAlertPresentation()
    
    private let refreshControl = UIRefreshControl()
    
    private var kMXCallStateDidChangeObserver: Any?
    
    private var fakeSyncData: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.addSubview(refreshControl)
        tableView.register(CKHeaderCallHistoryView.nib, forHeaderFooterViewReuseIdentifier: CKHeaderCallHistoryView.identifier)
        tableView.register(CKCallHistoryCell.nib, forCellReuseIdentifier: CKCallHistoryCell.identifier)
        
        refreshControl.addTarget(self, action: #selector(refreshCallHistory(sender:)), for: .valueChanged)
        
        bindingTheme()
        
        forceSyncCallHistory()
    }
    
    func listenCallNotifications() {
        kMXCallStateDidChangeObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: kMXCallStateDidChange), object: nil, queue: OperationQueue.main, using: { notif in
            
            guard let call = notif.object as? MXCall else { return }
            switch call.state {
            case .ended, .inviteExpired:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    self.refreshControl.sendActions(for: .valueChanged)
                }
            default:
                break
            }
        })
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if (MXKAccountManager.shared()?.accounts.isEmpty ?? true) {
            return
        }
        
        if fakeSyncData < 2 {
            fakeSyncData += 1
            refreshControl.sendActions(for: .valueChanged)
        }
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        kMXCallStateDidChangeObserver = nil
    }
    
    
    private func forceSyncCallHistory() {
        self.dataSource = nil
        self.dataSource = CKCallHistoryDataSource(matrixSession: self.mainSession)
        self.dataSource?.getListCallHistory(completion: { (event) in
            self.listCallHistory = event
        })
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
    
    
    @objc func displayList(_ aRecentsDataSource: MXKRecentsDataSource!) {
       // Report all matrix sessions at view controller level to update UI according to sessions state
       let mxSessions = aRecentsDataSource.mxSessions as? [MXSession]
       mxSessions.flatMap({ return $0 })?.forEach({ (mxSession) in
           self.addMatrixSession(mxSession)
           self.dataSource = CKCallHistoryDataSource(matrixSession: mxSession)
       })
        
       listenCallNotifications()
    }
    
    @objc private func refreshCallHistory(sender: Any) {
        forceSyncCallHistory()
    }
}


// MARK: UITableViewDelegate
extension CKCallHistoryViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
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
        return listCallHistory.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: CKCallHistoryCell.identifier,
                                                       for: indexPath) as? CKCallHistoryCell else {
            return UITableViewCell()
        }

        let model = listCallHistory[indexPath.row]
        cell.bindingData(model: model)

        if let directUserId = model.room.summary.directUserId {
            cell.status = checkOnline(directUserId) ? 1 : 0
        } else {
            cell.status = 0
        }
        
        cell.callAudioHander = {
            self.checkMediaPermission(video: false) { (result) in
                if result {
                    self.verifyCalling(room: model.room, isVideo: false)
                }
            }
        }

        cell.callVideoHander = {
            self.checkMediaPermission(video: true) { (result) in
                if result {
                    self.verifyCalling(room: model.room, isVideo: true)
                }
            }
        }

        return cell
    }
}

extension CKCallHistoryViewController {
    
    private func verifyCalling(room: MXRoom, isVideo: Bool) {
        
        findRoomState(room: room, isVideo: true) { (error, state) in
            if let `error` = error {
                self.alertError.presentError(from: self, title: "", message: error.errorDescription, animated: true, handler: nil)
                return
            }
            
            guard let roomState = state, MXCallManager.canPlaceConferenceCall(in: room, roomState: roomState) else {
                self.alertError.presentError(from: self, title: "", message: CKError.notAdminCallInRoom.errorDescription, animated: true, handler: nil)
                return
            }
            
            room.placeCall(withVideo: isVideo) { (call) in
                call.value?.answer()
            }
        }
    }
    
    private func findRoomState(room: MXRoom, isVideo: Bool, completion: @escaping ((CKError?, MXRoomState?) -> Void)) {
        
        let memberJoin = (room.summary.membersCount as MXRoomMembersCount).joined
        
        if memberJoin < 2 {
            completion(CKError.notEnoughMemberInRoom, nil)
        } else {
            room.state { (roomState) in
                completion(nil, roomState)
            }
        }
        
    }


    private func checkOnline(_ userId: String) -> Bool {
        guard let session = AppDelegate.the()?.mxSessions.first as? MXSession, let user = session.user(withUserId: userId) else {
            return false
        }
        
        switch user.presence {
        case MXPresenceOnline:
            return true
        default:
            return false
        }
    }
}


extension CKCallHistoryViewController {
    
    func checkMediaPermission(video: Bool, completion: ((Bool) -> Void)?) {
        let appDisplayName = (Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String) ?? ""
        
        // Check app permissions first
        
        let messageForAudio = String(format: Bundle.mxk_localizedString(forKey: "microphone_access_not_granted_for_call"), appDisplayName)
        let messageForVideo = String(format: Bundle.mxk_localizedString(forKey: "camera_access_not_granted_for_call"), appDisplayName)
        
        MXKTools.checkAccess(forCall: video, manualChangeMessageForAudio: messageForAudio, manualChangeMessageForVideo: messageForVideo, showPopUpIn: self) { (granted) in
            if granted {
                completion?(granted)
            } else {
                print("RoomViewController: Warning: The application does not have the perssion to place the call")
                completion?(false)
            }
        }
    }
}
