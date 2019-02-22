//
//  CKRoomSettingsGalleryViewController.swift
//  Riot
//
//  Created by Sinbad Flyce on 2/19/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKRoomSettingsGalleryViewController: MXKViewController {
    
    // MARK: - OULTET
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var blankView: UIView!
    
    // MARK: - PROPERTY
    
    /**
     Attachments
     */
    private var attachments: [MXKAttachment]!
    
    /**
     Number of items to get in paginate func
     */
    private let kPaginateLimit: UInt = 100
    
    /**
     Room object
     */
    public var mxRoom: MXRoom! {
        didSet {
            self.roomDataSource = MXKRoomDataSource(roomId: self.mxRoom.roomId, andMatrixSession: self.mxRoom.mxSession)
            self.roomDataSource.finalizeInitialization()
            self.roomDataSource.delegate = self
            self.roomDataSource.reload()
            self.startActivityIndicator()
        }
    }
    
    /**
     Room datasource
     */
    public var roomDataSource: MXKRoomDataSource!

    // MARK: - OVERRIDE
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Files"
        self.collectionView.register(CKRoomSettingsGalleryViewCell.nib, forCellWithReuseIdentifier: CKRoomSettingsGalleryViewCell.identifier)
        self.collectionView.reloadData()
        self.collectionView.backgroundColor = CKColor.Background.tableView
        self.updateBlank()
    }
    
    
    // MARK: - PRIVATE
    
    private func cellForGallery(_ indexPath: IndexPath) -> CKRoomSettingsGalleryViewCell {
        let cell = self.collectionView.dequeueReusableCell(
            withReuseIdentifier: CKRoomSettingsGalleryViewCell.identifier, for: indexPath) as! CKRoomSettingsGalleryViewCell
     
        return cell
    }
    
    /**
     Loading gallery
     */
    private func loadGallery(completion: (() -> (Void))? ) {
        
        // sure
        guard let ds = self.roomDataSource else {
            completion?()
            return
        }
        
        if ds.timeline?.canPaginate(MXTimelineDirection.backwards) == false {
            completion?()
            return
        }
        
        DispatchQueue.main.async { self.startActivityIndicator() }
        
        ds.paginate(
            kPaginateLimit, direction: __MXTimelineDirectionBackwards, onlyFromStore: false,
            success: { (numers: UInt) in
                DispatchQueue.main.async {
                    self.stopActivityIndicator()
                    completion?()
                }
        }) { (error: Error?) in
            print("Paginate error: \(String.init(describing: error?.localizedDescription))")
        }
    }
    
    /**
     Update blank view
     */
    private func updateBlank() {
        if (self.attachments?.count ?? 0) == 0 {
            self.blankView.isHidden = false
            self.collectionView.isHidden = true
        } else {
            self.blankView.isHidden = true
            self.collectionView.isHidden = false
        }
    }
    
    // MARK: - PUBLIC
}

// MARK: - UICollectionViewDelegate
extension CKRoomSettingsGalleryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.showAlert("Sorry! it should be coming soon")
    }
}

// MARK: - UICollectionViewDataSource
extension CKRoomSettingsGalleryViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.attachments?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        //cell
        let cell = self.cellForGallery(indexPath)
        
        // attachment
        let attachment = self.attachments[indexPath.item]
        
        // thumnail name
        cell.nameLabel.text = attachment.originalFileName
        
        // get attachment thumbnail
        attachment.getThumbnail({ (_, img: UIImage?) in
            
            // setimage
            cell.photoImage.image = img
        }, failure: { (_, _) in
            
            // failing
            cell.photoImage = nil
        })
        return cell
    }
}


// MARK: - MXKDataSourceDelegate
extension CKRoomSettingsGalleryViewController: MXKDataSourceDelegate {
    func cellViewClass(for cellData: MXKCellData!) -> MXKCellRendering.Type! {
        return nil
    }
    
    func cellReuseIdentifier(for cellData: MXKCellData!) -> String! {
        return nil
    }
    
    func dataSource(_ dataSource: MXKDataSource!, didCellChange changes: Any!) {
        return
    }
    
    func dataSource(_ dataSource: MXKDataSource!, didStateChange state: MXKDataSourceState) {
        if state == MXKDataSourceStateReady {
            self.loadGallery { () -> (Void) in
                if let attachments = self.roomDataSource.attachmentsWithThumbnail as? [MXKAttachment] {
                    self.attachments = attachments
                    self.collectionView.reloadData()
                    self.updateBlank()
                }
            }
        }
    }
}
