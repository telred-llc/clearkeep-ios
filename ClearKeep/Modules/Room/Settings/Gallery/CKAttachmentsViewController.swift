//
//  CKAttachmentsViewController.swift
//  Riot
//
//  Created by Developer Super on 3/26/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit
import AVKit

class CKAttachmentsViewController: MXKAttachmentsViewController {

    private let disposeBag = DisposeBag()
    
    /**
    Tells whether back pagination is in progress.
    */
    var isBackPaginationInProgress: Bool = false
    
    /**
    A temporary file used to store decrypted attachments
    */
    var tempFile: String = ""

    /**
        Path to a file containing video data for the currently selected
        attachment, if it's a video attachment and the data is
        available.
    */
    var videoFile: String = ""
    
    /**
        Audio session handling
    */
    var savedAVAudioSessionCategory: String = ""
    
    /**
    Navigation bar handling
    */
    var navigationBarDisplayTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.backButton.image = #imageLiteral(resourceName: "cancel").withRenderingMode(.alwaysTemplate)
        self.backButton.theme.tintColor = themeService.attrStream{ $0.navBarTintColor }
        bindingTheme()
        
//        self.navigationBar.frame.origin.y = self.safeArea.top == 44 ? self.safeArea.top : 0 // fix origin frame
        setupNavigationBar(color: .black)
    }

    private func bindingTheme() {
        // Binding navigation bar color
        themeService.attrsStream.subscribe(onNext: { [weak self] (theme) in
            self?.defaultBarTintColor = themeService.attrs.primaryBgColor
            self?.barTitleColor = themeService.attrs.primaryTextColor
            self?.activityIndicator?.backgroundColor = themeService.attrs.overlayColor
            self?.view.backgroundColor = themeService.attrs.primaryBgColor
        }).disposed(by: disposeBag)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // fixbug: CK 309 - app crash when touch search button
        // -- release CKAttachmentsViewController before dismiss display
        self.destroy()
    }
    
    
}

extension CKAttachmentsViewController {
    
    func setupNavigationBar(color: UIColor) {
        var alphaValue: CGFloat = 1.0
        color.getRed(nil, green: nil, blue: nil, alpha: &alphaValue)
        
        self.navigationBar.setBackgroundImage(UIImage.init(color: color), for: .default)
        self.navigationBar.isTranslucent = alphaValue < 1
        
        self.navigationBar.shadowImage = UIImage()
    }
}


// MARK: UICollectionViewDelegate
extension CKAttachmentsViewController {
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if #available(iOS 13.0, *) {
            
            var item = indexPath.item
            
            var navigationBarDisplayHandled: Bool = false
            
            if isBackPaginationInProgress {
                if item == 0 { return }
                item = item - 1
            }
            
            // Check whether the selected attachment is a video
            if (item < attachments.count) {
                
                if let attachment: MXKAttachment = attachments?[item] as? MXKAttachment, attachment.type == MXKAttachmentTypeVideo && !(attachment.contentURL ?? "").isEmpty {
                    
                    let selectedCell: MXKMediaCollectionViewCell = collectionView.cellForItem(at: indexPath) as! MXKMediaCollectionViewCell
                    
                    if selectedCell.movieAVPlayer == nil {
                        
                        try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                        selectedCell.movieAVPlayer = AVPlayerViewController()
                        
                        if selectedCell.movieAVPlayer != nil {
                            // Switch in custom view
                            selectedCell.mxkImageView.isHidden = true
                            selectedCell.customView.isHidden = false
                            
                            // Report the video preview
                            let previewImage = UIImageView(frame: selectedCell.customView.frame)
                            previewImage.contentMode = .scaleAspectFit
                            previewImage.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
                            previewImage.image = selectedCell.mxkImageView.image
                            previewImage.center = selectedCell.customView.center
                            selectedCell.customView.addSubview(previewImage) // add previewImage
                            
                            selectedCell.movieAVPlayer.view.frame = selectedCell.customView.frame
                            selectedCell.movieAVPlayer.view.center = selectedCell.customView.center
                            selectedCell.movieAVPlayer.view.isHidden = true
                            selectedCell.customView.addSubview(selectedCell.movieAVPlayer.view) // add movie player
                            
                            // Force the video to stay in fullscreen
                            if let movieView = selectedCell.movieAVPlayer.view {
                                movieView.translatesAutoresizingMaskIntoConstraints = false
                                movieView.leadingAnchor.constraint(equalTo: selectedCell.customView.leadingAnchor).isActive = true
                                movieView.trailingAnchor.constraint(equalTo: selectedCell.customView.trailingAnchor).isActive = true
                                movieView.topAnchor.constraint(equalTo: selectedCell.customView.topAnchor, constant: 0).isActive = true
                                movieView.bottomAnchor.constraint(equalTo: selectedCell.customView.bottomAnchor, constant: 0).isActive = true
                                
                            }
                            
                            NotificationCenter.default.addObserver(self, selector: #selector(movieAVPlayerPlaybackDidFinishNotification(_:)), name: NSNotification.Name.AVPlayerItemFailedToPlayToEndTime, object: selectedCell.movieAVPlayer.player)
                            
                        }
                    }
                    
                    if selectedCell.movieAVPlayer != nil {
                        
                        if selectedCell.movieAVPlayer.player?.timeControlStatus == .playing {
                            self.navigationBar.isHidden = !self.navigationBar.isHidden
                            
                            navigationBarDisplayHandled = true
                            
                            if (!self.navigationBar.isHidden) {
                                navigationBarDisplayTimer?.invalidate()
                                navigationBarDisplayTimer = nil
                                navigationBarDisplayTimer = Timer(timeInterval: 5, target: self, selector: #selector(hidenShowNavigationBar), userInfo: self, repeats: false)
                            }
                            
                        } else {
                            let pieChartView: MXKPieChartView = MXKPieChartView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
                            pieChartView.progress = 0
                            pieChartView.progressColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.25)
                            pieChartView.unprogressColor = UIColor.clear
                            pieChartView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
                            pieChartView.center = selectedCell.customView.center
                            
                            selectedCell.customView.addSubview(pieChartView)
                            
                            // Add download progress observer
                            let downloadId = attachment.downloadId ?? ""
                            selectedCell.notificationObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.mxMediaLoaderStateDidChange, object: nil, queue: OperationQueue.main, using: { (notif) in
                                
                                if let loader: MXMediaLoader = notif.object as? MXMediaLoader, loader.downloadId == downloadId {
                                    // update progress
                                    switch loader.state {
                                    case MXMediaLoaderStateDownloadInProgress:
                                        if let statisticsDict = loader.statisticsDict, let progressNumber: NSNumber = statisticsDict.value(forKey: kMXMediaLoaderProgressValueKey) as? NSNumber {
                                            pieChartView.progress = CGFloat(progressNumber.floatValue)
                                        }
                                    default:
                                        break
                                    }
                                }
                            })
                            
                            // ----
                            self.prepareVideo(forItem: item, success: {
                                
                                if selectedCell.notificationObserver != nil {
                                    NotificationCenter.default.removeObserver(selectedCell.notificationObserver)
                                    selectedCell.notificationObserver = nil
                                }
                                
                    
                                if selectedCell.movieAVPlayer.view.superview != nil {
                                    selectedCell.movieAVPlayer.view.isHidden = false
                                    selectedCell.centerIcon.isHidden = true
                                    
                                    let playerURL = URL(fileURLWithPath: self.videoFile)
                                    selectedCell.movieAVPlayer.player = AVPlayer(url: playerURL)
                                    selectedCell.movieAVPlayer.player?.allowsExternalPlayback = false
                                    selectedCell.movieAVPlayer.player?.usesExternalPlaybackWhileExternalScreenIsActive = false
                                    selectedCell.movieAVPlayer.player?.play()
                                    
                                    pieChartView.removeFromSuperview()
                                    
                                    self.hidenShowNavigationBar()
                                    
                                    selectedCell.layoutIfNeeded()
                                }
                                
                            }) { (error) in
                                
                                if selectedCell.notificationObserver != nil {
                                    NotificationCenter.default.removeObserver(selectedCell.notificationObserver)
                                    selectedCell.notificationObserver = nil
                                }
                                
                                print("[CKAttachmentsViewController] video download failed")
                                pieChartView.removeFromSuperview()
                                
                                // Display the navigation bar so that the user can leave this screen
                                self.navigationBar.isHidden = false
                                
                                // Notify MatrixKit user
                                NotificationCenter.default.post(name: NSNotification.Name.mxkError, object: error)
                            }
                            
                            // Do not animate the navigation bar on video playback preparing
                            return
                        }
                    }
                }
            }
            
            /* Animate navigation bar if it is has not been handled */
            if !navigationBarDisplayHandled {
                if self.navigationBar.isHidden {
                    self.navigationBar.isHidden = false
                    navigationBarDisplayTimer?.invalidate()
                    navigationBarDisplayTimer = Timer(timeInterval: 3, target: self, selector: #selector(hidenShowNavigationBar), userInfo: self, repeats: false)
                } else {
                    self.hidenShowNavigationBar()
                }
            }
            
        } else {
            super.collectionView(collectionView, didSelectItemAt: indexPath)
        }
    }
}


// MARK: Notification AVPlayer
extension CKAttachmentsViewController {
    
    @objc func movieAVPlayerPlaybackDidFinishNotification(_ notification: Notification) {
          
        if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error {
            print("CKAttachmentsViewController: -------> ", error.localizedDescription)
            self.navigationBar.isHidden = true
            NotificationCenter.default.post(name: NSNotification.Name.mxkError, object: error)
        }
    }
}

extension CKAttachmentsViewController {
    
    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        if #available(iOS 13.0, *) {
            if let mediaCollectionViewCell: MXKMediaCollectionViewCell = cell as? MXKMediaCollectionViewCell {
                // Check whether a video was playing in this cell.
                if mediaCollectionViewCell.movieAVPlayer != nil {
                    // This cell concerns an attached video.
                    mediaCollectionViewCell.movieAVPlayer.player?.pause()
                    mediaCollectionViewCell.movieAVPlayer = nil
                    
                    mediaCollectionViewCell.mxkImageView.isHidden = false
                    mediaCollectionViewCell.centerIcon.isHidden = false
                    mediaCollectionViewCell.customView.isHidden = true
                    
                    // Remove potential media download observer
                    if mediaCollectionViewCell.notificationObserver != nil {
                        NotificationCenter.default.removeObserver(mediaCollectionViewCell.notificationObserver)
                        mediaCollectionViewCell.notificationObserver = nil
                    }
                }
            }
        } else {
            super.collectionView(collectionView, didEndDisplaying: cell, forItemAt: indexPath)
        }
    }
}

extension CKAttachmentsViewController {
    
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let height = UIScreen.main.bounds.height// - self.safeArea.top
        
        return CGSize(width: UIScreen.main.bounds.width, height: height)
    }
    
    @objc
    func hidenShowNavigationBar() {
        self.navigationBar.isHidden = true
        self.navigationBarDisplayTimer?.invalidate()
        self.navigationBarDisplayTimer = nil
    }

    
}

// MARK: Handler Video For Item
extension CKAttachmentsViewController {
    
    func prepareVideo(forItem item: Int, success: @escaping () -> Void, failure: @escaping (Error?) -> Void) {
        
        guard let attachment: MXKAttachment = attachments?[item] as? MXKAttachment else { return }

        if attachment.isEncrypted {
            attachment.decrypt(toTempFile: { (file) in
                if !self.tempFile.isEmpty {
                    try? FileManager.default.removeItem(atPath: self.tempFile)
                }

                self.tempFile = file ?? ""
                self.videoFile = file ?? ""
                success()

            }) { (error) in
                failure(error)
            }
            
        } else {
            
            if FileManager.default.fileExists(atPath: attachment.cacheFilePath ?? "") {
                videoFile = attachment.cacheFilePath ?? ""
                success()
            } else {
                attachment.prepare({
                    self.videoFile = attachment.cacheFilePath ?? ""
                    success()
                }) { (error) in
                    failure(error)
                }
            }
        }
    }

}
