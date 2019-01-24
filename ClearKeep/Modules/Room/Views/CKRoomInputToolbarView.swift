//
//  CKRoomInputToolbarView.swift
//  Riot
//
//  Created by Pham Hoa on 1/18/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit
import HPGrowingTextView

@objc protocol CKRoomInputToolbarViewDelegate: MXKRoomInputToolbarViewDelegate {
    @objc optional func roomInputToolbarView(_ toolbarView: MXKRoomInputToolbarView?, triggerMention: Bool, mentionText: String?)
}

final class CKRoomInputToolbarView: MXKRoomInputToolbarViewWithHPGrowingText {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var mainToolbarMinHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var mainToolbarHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var mainToolbarView: UIView!
    @IBOutlet weak var separatorView: UIView!
    
    // MARK: - Constants
    
    private let mentionTriggerCharacter: Character = "@"
    
    // MARK: - Properties
    
    var growingTextView: HPGrowingTextView? {
        get {
            return self.value(forKey: "growingTextView") as? HPGrowingTextView
        }
        set {
            self.setValue(growingTextView, forKey: "growingTextView")
        }
    }
    
    private weak var ckDelegate: CKRoomInputToolbarViewDelegate? {
        get {
            return self.delegate as? CKRoomInputToolbarViewDelegate
        }
        set {
            self.delegate = newValue
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
        if growingTextView?.isFirstResponder() != true {
            growingTextView?.becomeFirstResponder()
        }
        
        if var selectedRange = growingTextView?.selectedRange {
            let firstHalfString = (growingTextView?.text as NSString?)?.substring(to: selectedRange.location)
            let secondHalfString = (growingTextView?.text as NSString?)?.substring(from: selectedRange.location)

            let insertingString = String.init(mentionTriggerCharacter)

            growingTextView?.text = "\(firstHalfString ?? "")\(insertingString)\(secondHalfString ?? "")"
            selectedRange.location += insertingString.count
            growingTextView?.selectedRange = selectedRange
        }
    }
    
    @IBAction func clickedOnShareFileButton(_ sender: Any) {
    }
    
    @IBAction func clickedOnShareImageButton(_ sender: Any) {
    }
}

private extension CKRoomInputToolbarView {
    func triggerMentionUser(_ flag: Bool, text: String?) {
        ckDelegate?.roomInputToolbarView?(self, triggerMention: flag, mentionText: text)
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
        
        let firstHalfString = (growingTextView.text as NSString?)?.substring(to: growingTextView.selectedRange.location)
        
        if firstHalfString?.contains(String.init(mentionTriggerCharacter)) == true {
            let mentionComponents = firstHalfString?.components(separatedBy: String.init(mentionTriggerCharacter))
            let currentMentionComponent = mentionComponents?.last
            
            if let currentMentionComponent = currentMentionComponent,
                !currentMentionComponent.contains(" ") {
                triggerMentionUser(true, text: currentMentionComponent)
            } else {
                triggerMentionUser(false, text: nil)
            }
        } else {
            triggerMentionUser(false, text: nil)
        }
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
    
    override func growingTextView(_ growingTextView: HPGrowingTextView!, shouldChangeTextIn range: NSRange, replacementText text: String!) -> Bool {
        return true
    }
}
