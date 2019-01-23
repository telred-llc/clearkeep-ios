//
//  CKRoomInputToolbarView.swift
//  Riot
//
//  Created by Pham Hoa on 1/18/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit
import HPGrowingTextView

class CKRoomInputToolbarView: MXKRoomInputToolbarViewWithHPGrowingText {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var mainToolbarMinHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var mainToolbarHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var mainToolbarView: UIView!
    @IBOutlet weak var separatorView: UIView!
    
    // MARK: - Constants
    
    
    // MARK: - Properties
    
    var growingTextView: HPGrowingTextView? {
        get {
            return self.value(forKey: "growingTextView") as? HPGrowingTextView
        }
        set {
            self.setValue(growingTextView, forKey: "growingTextView")
        }
    }
    
    // MARK: - LifeCycle

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override class func nib() -> UINib? {
        return UINib.init(
            nibName: String(describing: CKRoomInputToolbarView.self),
            bundle: Bundle(for: self))
    }

    class func initRoomInputToolbarView() -> CKRoomInputToolbarView {
        if self.nib() != nil {
            return self.nib()?.instantiate(withOwner: nil, options: nil).first as! CKRoomInputToolbarView
        } else {
            return super.init() as! CKRoomInputToolbarView
        }
    }
    
    override func customizeRendering() {
        super.customizeRendering()
        
        // Remove default toolbar background color
        backgroundColor = UIColor.clear
        
        separatorView?.backgroundColor = kRiotAuxiliaryColor
        
        // Custom the growingTextView display
        growingTextView?.layer.cornerRadius = 0
        growingTextView?.layer.borderWidth = 0
        growingTextView?.backgroundColor = UIColor.clear

        growingTextView?.font = UIFont.systemFont(ofSize: 15)
        growingTextView?.textColor = kRiotPrimaryTextColor
        growingTextView?.tintColor = kRiotColorGreen
        growingTextView?.maxNumberOfLines = 2
        
        growingTextView?.internalTextView?.keyboardAppearance = kRiotKeyboard
        growingTextView?.placeholder = "Type a Message"
    }
    
    // MARK: - IBActions
    
    @IBAction func clickedOnMentionButton(_ sender: Any) {
    }
    
    @IBAction func clickedOnShareFileButton(_ sender: Any) {
    }
    
    @IBAction func clickedOnShareImageButton(_ sender: Any) {
    }
}

extension CKRoomInputToolbarView: MediaPickerViewControllerDelegate {
    func mediaPickerController(_ mediaPickerController: MediaPickerViewController!, didSelectImage imageData: Data!, withMimeType mimetype: String!, isPhotoLibraryAsset: Bool) {
        
    }
    
    func mediaPickerController(_ mediaPickerController: MediaPickerViewController!, didSelectVideo videoURL: URL!) {
        
    }
}

extension CKRoomInputToolbarView {
    override func growingTextViewDidChange(_ growingTextView: HPGrowingTextView!) {
        // Clean the carriage return added on return press
        if (textMessage == "\n") {
            textMessage = nil
        }
        
        super.growingTextViewDidChange(growingTextView)
    }
    
    override func growingTextView(_ growingTextView: HPGrowingTextView!, willChangeHeight height: Float) {
        // Update height of the main toolbar (message composer)
        var updatedHeight: CGFloat = CGFloat(height) + (messageComposerContainerTopConstraint.constant + messageComposerContainerBottomConstraint.constant)

        if updatedHeight < mainToolbarMinHeightConstraint.constant {
            updatedHeight = mainToolbarMinHeightConstraint.constant
        }
        
        mainToolbarHeightConstraint.constant = updatedHeight
        
        self.delegate?.roomInputToolbarView?(self, heightDidChanged: updatedHeight, completion: { (_) in
            //
        })
    }
}
