//
//  CKCallingViewController.swift
//  Riot
//
//  Created by Pham Hoa on 2/2/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKCallViewController: CallViewController {
    
    private let maxCallControlItemWidth: CGFloat = 65
    private let minCallControlsSpacing: CGFloat = 6
    private let disposeBag = DisposeBag()
    private var pulseArray = [CAShapeLayer]()
    private var statusTimer = Timer()

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: CKCallViewController.nibName, bundle: Bundle.init(for: CKCallViewController.self))
    }

    @IBOutlet weak var pulseView: UIView!
    @IBOutlet weak var callControlContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageSwitchView: UIView!
    @IBOutlet weak var cameraSwitchView: UIView!
    @IBOutlet weak var sideControlView: UIView!
    @IBOutlet var previewBottomConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        bindingTheme()
    }

    private func bindingTheme() {
        let image = UIImage.init(named: "back_icon")?.withRenderingMode(.alwaysTemplate)
        self.backToAppButton.setImage(image, for: .normal)
        // Binding navigation bar color
        self.callStatusLabel.theme.textColor = themeService.attrStream{$0.secondTextColor}
        themeService.attrsStream.subscribe(onNext: { [weak self] (theme) in
            self?.callerNameLabel.textColor = themeService.attrs.primaryTextColor
            self?.view.backgroundColor = themeService.attrs.navBarBgColor
            self?.backToAppButton.tintColor = themeService.attrs.primaryTextColor
        }).disposed(by: disposeBag)
    }
    
    func roundButtons() {
        roundView(viewBoder: audioMuteButton)
        roundView(viewBoder: videoMuteButton)
        roundView(viewBoder: speakerButton)
        roundView(viewBoder: chatButton)
        roundView(viewBoder: endCallButton)        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // update layout
        let screenWidth = UIScreen.main.bounds.size.width
        let controlItemsCount: CGFloat = 5
        let minTotlaSpacing = (controlItemsCount + 1.0) * minCallControlsSpacing
        let maxAbleControlItemWidth = (screenWidth - minTotlaSpacing) / controlItemsCount

        if maxCallControlItemWidth > maxAbleControlItemWidth {
            self.callControlContainerHeightConstraint.constant = maxAbleControlItemWidth
        } else {
            self.callControlContainerHeightConstraint.constant = maxCallControlItemWidth
        }
        
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()

        self.backToAppButton.isHidden = true
        createPulse(sourceView: pulseView)

        if let call = self.mxCall, call.isVideoCall {
            self.pulseView.isHidden = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        pulseArray.forEach { (item) in
            item.strokeColor = UIColor.clear.cgColor
        }
    }
    
    func roundView(viewBoder: UIView, color: UIColor = CKColor.Background.primaryGreenColor) {
        viewBoder.backgroundColor = UIColor(white: 1, alpha: 0.35)
        viewBoder.layer.borderWidth = 1
        viewBoder.layer.borderColor = color.cgColor
        viewBoder.layer.cornerRadius = (viewBoder.bounds.height)/2
        viewBoder.layer.masksToBounds = true        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        //self.roundButtons()
    }
    
    override func startActivityIndicator() {
        // TODO: Temporary fixing
    }

    override func setMxCall(_ call: MXCall!) {
        super.setMxCall(call)
        if let object = call, !object.isVideoCall {
            self.view.bringSubview(toFront: self.pulseView)
            self.view.bringSubview(toFront: self.callerImageView)
            self.callerImageView.isHidden = false
            self.callContainerView.isHidden = false
            self.audioMuteButton.isSelected = false
        } else {
            self.sideControlView.isHidden = false
            self.callContainerView.isHidden = true
            self.callerImageView.isHidden = true
            self.pulseView.isHidden = true
            self.audioMuteButton.isSelected = false
            self.videoMuteButton.isSelected = false
            self.cameraSwitchView.isHidden = false
            self.messageSwitchView.isHidden = true
        }
    }
    
    override func call(_ call: MXCall, stateDidChange state: MXCallState, reason event: MXEvent?) {
        super.call(call, stateDidChange: state, reason: event)
        if state == .connected {
            self.pulseView.isHidden = true
            statusTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimeLabel), userInfo: nil, repeats: true)

            if call.isVideoCall {
                self.callerImageView.isHidden = true
                self.resetPreviewSize()
            }
            self.audioMuteButton.isSelected = call.audioMuted
            self.videoMuteButton.isSelected = call.videoMuted
            self.smallTimeLabel.isHidden = !call.isVideoCall
            self.sideControlView.isHidden = !call.isVideoCall
            self.cameraSwitchView.isHidden = !call.isVideoCall
            self.messageSwitchView.isHidden = call.isVideoCall
            self.callStatusLabel.isHidden = call.isVideoCall
            self.callerNameLabel.isHidden = call.isVideoCall
            self.smallTimeLabel.theme.textColor = themeService.attrStream{$0.navBarTintColor}
            self.callStatusLabel.theme.textColor = themeService.attrStream{$0.navBarTintColor}
        } else {
            call.endReason
            statusTimer.invalidate()
            self.cameraSwitchView.isHidden = !call.isVideoCall
            self.callerImageView.isHidden = false
            self.pulseView.isHidden = false
            self.messageSwitchView.isHidden = call.isVideoCall
            self.sideChatButton.isHidden = !self.messageSwitchView.isHidden
        }
    }

    override func call(_ call: MXCall, didEncounterError error: Error?) {
        
        guard let nsError = error as NSError? else {
            return
        }
        
        if nsError._domain == MXEncryptingErrorDomain && nsError._code == Int(MXEncryptingErrorUnknownDeviceCode.rawValue) {
            // There are unknown devices -> call anyway

            let unknownDevices = nsError.userInfo[MXEncryptingErrorUnknownDeviceDevicesKey] as? MXUsersDevicesMap<MXDeviceInfo>

            // Acknowledge the existence of all devices
            
            self.mainSession?.crypto?.setDevicesKnown(unknownDevices) {
                
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
        super.onButtonPressed(sender)
    }
    
    override func updateLocalPreviewLayout() {
        super.updateLocalPreviewLayout()
        
        if let call = self.mxCall, call.state == .connected {
            return
        } else {
            self.previewBottomConstraint.isActive = false
            self.localPreviewContainerViewTopConstraint.constant = 0.0
            self.localPreviewContainerViewLeadingConstraint.constant = 0.0
            self.localPreviewContainerViewWidthConstraint.constant = UIScreen.main.bounds.size.width
            self.localPreviewContainerViewHeightConstraint.constant = UIScreen.main.bounds.size.height
        }
        
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
    }
    
    private func resetPreviewSize() {
        if self.previewBottomConstraint.isActive {
            return
        }
        self.previewBottomConstraint.isActive = true
        self.localPreviewContainerViewLeadingConstraint.constant = 20
        self.localPreviewContainerViewWidthConstraint.constant = 79
        self.localPreviewContainerViewHeightConstraint.constant = 106

        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()

        self.updateLocalPreviewLayout()
    }
    
    func createPulse(sourceView: UIView) {
        sourceView.layer.cornerRadius = sourceView.bounds.height / 2
        sourceView.borderWidth = 1.0
        sourceView.borderColor = .lightGray
        for _ in 0...2 {
            let circularPath = UIBezierPath(arcCenter: .zero, radius: ((sourceView.superview?.frame.size.width )!) / 2,
                                            startAngle: 0,
                                            endAngle: 2 * .pi,
                                            clockwise: true)
            let pulsatingLayer = CAShapeLayer()
            pulsatingLayer.path = circularPath.cgPath
            pulsatingLayer.lineWidth = 20
            pulsatingLayer.fillColor = UIColor.clear.cgColor
            pulsatingLayer.lineCap = kCALineCapRound
            pulsatingLayer.position = CGPoint(x: sourceView.frame.size.width / 2.0, y: sourceView.frame.size.width / 2.0)
            sourceView.layer.addSublayer(pulsatingLayer)
            pulseArray.append(pulsatingLayer)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
            self.animatePulsatingLayerAt(index: 0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                self.animatePulsatingLayerAt(index: 1)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                    self.animatePulsatingLayerAt(index: 2)
                })
            })
        })
    }
    
    func animatePulsatingLayerAt(index:Int) {
        if index >= pulseArray.count {
            return
        }

        //Giving color to the layer
        pulseArray[index].theme.strokeColor = themeService.attrStream{$0.pulseLayerColor.cgColor}

        //Creating scale animation for the layer, from and to value should be in range of 0.0 to 1.0
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 0.5
        scaleAnimation.toValue = 0.9
        
        //Creating opacity animation for the layer, from and to value should be in range of 0.0 to 1.0
        let opacityAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        opacityAnimation.fromValue = 1.4
        opacityAnimation.toValue = 0

        // Grouping both animations and giving animation duration, animation repeat count
        let groupAnimation = CAAnimationGroup()
        groupAnimation.animations = [scaleAnimation, opacityAnimation]
        groupAnimation.duration = 3.5
        groupAnimation.repeatCount = .greatestFiniteMagnitude
        groupAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)

        //adding groupanimation to the layer
        pulseArray[index].add(groupAnimation, forKey: "groupanimation")
    }
    
    @objc private func updateTimeLabel() {
        if let call = mxCall {
            let duration = call.duration / 1000;
            let secs = duration % 60;
            let mins = (duration - secs) / 60;
            smallTimeLabel.text = String.init(format: "%02tu:%02tu", mins, secs)
        }
    }
}

extension CKCallViewController {
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !self.previewBottomConstraint.isActive {
            return
        }
        super.touchesMoved(touches, with: event)
    }
}
