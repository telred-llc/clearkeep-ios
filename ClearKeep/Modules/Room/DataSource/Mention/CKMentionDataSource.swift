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
                var avatarThumbURL: String? = nil
                if let avatarUrl = member.avatarUrl {
                    // Suppose this url is a matrix content uri, we use SDK to get the well adapted thumbnail from server
                    avatarThumbURL = mxSession.matrixRestClient.url(ofContentThumbnail: avatarUrl, toFitViewSize: cell.avatarImageView.frame.size, with: MXThumbnailingMethodCrop)
                }
                cell.avatarImageView.enableInMemoryCache = true
                cell.avatarImageView.setImageURL(avatarThumbURL, withType: nil, andImageOrientation: UIImage.Orientation.up, previewImage: preview)

            } else {
                cell.avatarImageView.image = nil
            }
        } else {
            cell.usernameLabel.text = nil
            cell.avatarImageView.image = nil
        }
        
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
