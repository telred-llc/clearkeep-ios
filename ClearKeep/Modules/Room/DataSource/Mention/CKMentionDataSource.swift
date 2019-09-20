//
//  CKMentionDataSource.swift
//  Riot
//
//  Created by Pham Hoa on 1/24/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

@objc protocol CKMentionDataSourceDelegate: MXKDataSourceDelegate {
    @objc optional func mentionDataSource(_ dataSource: CKMentionDataSource, didSelect member: MXRoomMember)
}

final class CKMentionDataSource: MXKDataSource {
    
    // MARK: - Constants
    
    private let cellId = ""
    
    // MARK: - Properties
    
    // MARK: Public
    
    // MARK: Private
    
    private var roomMembers: [MXRoomMember] = []
    private weak var ckDelegate: CKMentionDataSourceDelegate? {
        get {
            return self.delegate as? CKMentionDataSourceDelegate
        }
        set {
            self.delegate = newValue
        }
    }
    
    
    override init() {
        super.init()
    }

    init(_ roomMembers: [MXRoomMember], matrixSession mxSession: MXSession!, delegate: CKMentionDataSourceDelegate?) {
        super.init(matrixSession: mxSession)
        self.ckDelegate = delegate
        self.roomMembers = roomMembers
    }
}

// MARK: - UITableViewDataSource

extension CKMentionDataSource: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return roomMembers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CKMentionUserTableViewCell.defaultReuseIdentifier(), for: indexPath) as? CKMentionUserTableViewCell else {
            return UITableViewCell.init(style: .default, reuseIdentifier: "fakeCell")
        }
        
        if indexPath.row < roomMembers.count {
            let member = roomMembers[indexPath.row]
            
            cell.usernameLabel.text = member.displayname
            
            if let userId = member.userId, let displayname = member.displayname {
                let preview: UIImage? = AvatarGenerator.generateAvatar(forMatrixItem: userId, withDisplayName: displayname)
                cell.avatarImageView.enableInMemoryCache = true
                cell.avatarImageView.setImageURI(member.avatarUrl,
                                                 withType: nil,
                                                 andImageOrientation: UIImageOrientation.up,
                                                 toFitViewSize: cell.avatarImageView.frame.size,
                                                 with: MXThumbnailingMethodCrop,
                                                 previewImage: preview,
                                                 mediaManager: mxSession?.mediaManager)
            } else {
                cell.avatarImageView.image = nil
            }
        } else {
            cell.usernameLabel.text = nil
            cell.avatarImageView.image = nil
        }

        cell.usernameLabel.textColor = themeService.attrs.primaryTextColor
        cell.backgroundColor = themeService.attrs.primaryBgColor
        return cell
    }
}

extension CKMentionDataSource: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row < self.roomMembers.count {
            let member = self.roomMembers[indexPath.row]
            ckDelegate?.mentionDataSource?(self, didSelect: member)
        }
    }
}
