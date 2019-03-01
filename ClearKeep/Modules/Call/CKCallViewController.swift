//
//  CKCallingViewController.swift
//  Riot
//
//  Created by Pham Hoa on 2/2/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKCallViewController: CallViewController {
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: CKCallViewController.nibName, bundle: Bundle.init(for: CKCallViewController.self))
    }
    @IBOutlet weak var distanceOverViewToBottom: NSLayoutConstraint!
    @IBOutlet weak var distanceOverViewToTop: NSLayoutConstraint!
    @IBOutlet weak var distancelocalPreviewToBottom: NSLayoutConstraint!
    override func viewDidLoad() {
        super.viewDidLoad()
        // set backgound View
         self.view.backgroundColor = UIColor.init(red: 57/255, green: 73/255, blue: 99/255, alpha: 1)
        
        // check device
        if UIDevice().userInterfaceIdiom == .phone {
            if UIScreen.main.bounds.height >= 812 {
                // iphone X and later
                distanceOverViewToTop.constant = 44
                distanceOverViewToBottom.constant = 34
                distancelocalPreviewToBottom.constant = 240
            } else {
                // before iphone X
                distanceOverViewToTop.constant = 0
                distanceOverViewToBottom.constant = 0
                distancelocalPreviewToBottom.constant = 140
                if UIScreen.main.bounds.height > 667 {
                    distancelocalPreviewToBottom.constant = 74
                }
            }
        }
        
        backToAppButton.setImage(UIImage(named: "ic_back_white"), for: .normal)
        backToAppButton.setImage(UIImage(named: "ic_back_white"), for: .highlighted)
        
        cameraSwitchButton.setImage(UIImage(named: "camera_switch"), for: .normal)
        cameraSwitchButton.setImage(UIImage(named: "camera_switch"), for: .highlighted)
        
        audioMuteButton.setImage(UIImage(named: "ic_voice_off"), for: .normal)
        audioMuteButton.setImage(UIImage(named: "ic_voice_off"), for: .highlighted)
        audioMuteButton.setImage(UIImage(named: "ic_voice_on"), for: .selected)
        videoMuteButton.setImage(UIImage(named: "call_video_mute_off_icon"), for: .normal)
        videoMuteButton.setImage(UIImage(named: "call_video_mute_off_icon"), for: .highlighted)
        videoMuteButton.setImage(UIImage(named: "call_video_mute_on_icon"), for: .selected)
        speakerButton.setImage(UIImage(named: "ic_volume_off"), for: .normal)
        speakerButton.setImage(UIImage(named: "ic_volume_on"), for: .selected)
        chatButton.setImage(UIImage(named: "ic_messeger"), for: .normal)
        chatButton.setImage(UIImage(named: "ic_messeger"), for: .highlighted)
        
        endCallButton.setTitle(nil, for: .normal)
        endCallButton.setTitle(nil, for: .highlighted)
        endCallButton.setImage(UIImage(named: "call_hangup_icon"), for: .normal)
        endCallButton.setImage(UIImage(named: "call_hangup_icon"), for: .highlighted)
        
        boderView(viewBoder: audioMuteButton)
        boderView(viewBoder: videoMuteButton)
        boderView(viewBoder: speakerButton)
        boderView(viewBoder: chatButton)
        boderView(viewBoder: endCallButton)
        
        callControlContainerView.backgroundColor = .clear
        callerNameLabel.textColor = .white
    }
    
    func boderView(viewBoder: UIView) {
        viewBoder.backgroundColor = .white
        viewBoder.layer.borderWidth = 1
        viewBoder.layer.borderColor = UIColor.clear.cgColor
        viewBoder.layer.cornerRadius = viewBoder.bounds.height/2
        viewBoder.layer.masksToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func call(_ call: MXCall, didEncounterError error: Error?) {
        
        guard let nsError = error as NSError? else {
            return
        }
        
        if nsError._domain == MXEncryptingErrorDomain && nsError._code == Int(MXEncryptingErrorUnknownDeviceCode.rawValue) {
            // There are unknown devices -> call anyway

            let unknownDevices = nsError.userInfo[MXEncryptingErrorUnknownDeviceDevicesKey] as? MXUsersDevicesMap<MXDeviceInfo>

            // Acknowledge the existence of all devices

            startActivityIndicator()
            self.mainSession?.crypto?.setDevicesKnown(unknownDevices) { [weak self] in
                
                self?.stopActivityIndicator()
                
                // Retry the call
                if call.isIncoming {
                    call.answer()
                } else {
                    call.call(withVideo: call.isVideoCall)
                }
            }
        } else {
            super.call(call, didEncounterError: error!)
        }
    }
    
    override func onButtonPressed(_ sender: Any!) {
        let sender = sender as? UIButton
        switch sender {
        case answerCallButton:
            answerCallButton.isSelected = !answerCallButton.isSelected
            if answerCallButton.isSelected {
                answerCallButton.backgroundColor = .darkGray
            } else {
                answerCallButton.backgroundColor = .white
            }
        case audioMuteButton:
            audioMuteButton.isSelected = !audioMuteButton.isSelected
            if audioMuteButton.isSelected {
                audioMuteButton.backgroundColor = .darkGray
            } else {
                audioMuteButton.backgroundColor = .white
            }
        case videoMuteButton:
            videoMuteButton.isSelected = !videoMuteButton.isSelected
            if videoMuteButton.isSelected {
                videoMuteButton.backgroundColor = .darkGray
            } else {
                videoMuteButton.backgroundColor = .white
            }
        case speakerButton:
            speakerButton.isSelected = !speakerButton.isSelected
            if speakerButton.isSelected {
                speakerButton.backgroundColor = .darkGray
            } else {
                speakerButton.backgroundColor = .white
            }
        case chatButton:
            chatButton.isSelected = !chatButton.isSelected
            if chatButton.isSelected {
                chatButton.backgroundColor = .darkGray
            } else {
                chatButton.backgroundColor = .white
            }
        case endCallButton:
            endCallButton.isSelected = !endCallButton.isSelected
            if endCallButton.isSelected {
                endCallButton.backgroundColor = .darkGray
            } else {
                endCallButton.backgroundColor = .white
            }
        default:
            break
        }
        
        // Check
        if sender == chatButton {
            if ((self.delegate) != nil) {
                // Dismiss the view controller whereas the call is still running
                delegate.dismiss(self) {
                    if ((self.mxCall?.room) != nil) {
                        // Open the room page
                        AppDelegate.the().showRoom(self.mxCall.room.roomId, andEventId: nil, withMatrixSession: self.mxCall.room.mxSession)
                    }
                }
            }
        } else if sender == audioMuteButton || sender == videoMuteButton || sender == speakerButton {
            
        } else {
            super.onButtonPressed(sender)
        }
    }
    
}
