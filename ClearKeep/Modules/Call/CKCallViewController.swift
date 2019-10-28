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
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: CKCallViewController.nibName, bundle: Bundle.init(for: CKCallViewController.self))
    }
    
    @IBOutlet weak var pulseView: UIView!
    @IBOutlet weak var callControlContainerHeightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.roundButtons()
        bindingTheme()
    }

    private func bindingTheme() {
        let image = UIImage.init(named: "back_icon")?.withRenderingMode(.alwaysTemplate)
        self.backToAppButton.setImage(image, for: .normal)
        // Binding navigation bar color
        themeService.attrsStream.subscribe(onNext: { [weak self] (theme) in
            self?.callerNameLabel.textColor = themeService.attrs.primaryTextColor
            self?.callStatusLabel.textColor = themeService.attrs.secondTextColor
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
        createPulse(sourceView: pulseView)
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
        self.callerImageView.isHidden = false
        self.view.bringSubview(toFront: self.pulseView)
        self.view.bringSubview(toFront: self.callerImageView)
    }
    
    override func call(_ call: MXCall, stateDidChange state: MXCallState, reason event: MXEvent?) {
        super.call(call, stateDidChange: state, reason: event)
        print("")
        if state == .connected {
            if  call.isVideoCall {
                self.callerImageView.isHidden = true
            }
            self.pulseView.isHidden = true
        } else {
            self.callerImageView.isHidden = false
            self.pulseView.isHidden = false
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: {
                self.animatePulsatingLayerAt(index: 1)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
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
        pulseArray[index].strokeColor = CKColor.Misc.pulseCicleColor.cgColor
        
        //Creating scale animation for the layer, from and to value should be in range of 0.0 to 1.0
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 0.0
        scaleAnimation.toValue = 0.75
        
        //Creating opacity animation for the layer, from and to value should be in range of 0.0 to 1.0
        let opacityAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        opacityAnimation.fromValue = 1.0
        opacityAnimation.toValue = 0.0
        
        // Grouping both animations and giving animation duration, animation repat count
        let groupAnimation = CAAnimationGroup()
        groupAnimation.animations = [scaleAnimation, opacityAnimation]
        groupAnimation.duration = 3.3
        groupAnimation.repeatCount = .greatestFiniteMagnitude
        groupAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        //adding groupanimation to the layer
        pulseArray[index].add(groupAnimation, forKey: "groupanimation")
    }
    
}
