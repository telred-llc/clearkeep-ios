//
//  DesignableUI.swift
//  Riot
//
//  Created by Hiếu Nguyễn on 12/19/18.
//  Copyright © 2018 matrix.org. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class View : UIView {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if cornerRadius == -1 {
            self.layer.cornerRadius = self.bounds.width < self.bounds.height ? self.bounds.width * 0.5 : self.bounds.height * 0.5
        }
    }
    
    @IBInspectable var gradientColor1: UIColor = UIColor.white {
        didSet{
            self.setGradient()
        }
    }
    
    @IBInspectable var gradientColor2: UIColor = UIColor.white {
        didSet{
            self.setGradient()
        }
    }
    
    @IBInspectable var gradientStartPoint: CGPoint = .zero {
        didSet{
            self.setGradient()
        }
    }
    
    @IBInspectable var gradientEndPoint: CGPoint = CGPoint(x: 0, y: 1) {
        didSet{
            self.setGradient()
        }
    }
    
    private func setGradient()
    {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [self.gradientColor1.cgColor, self.gradientColor2.cgColor]
        gradientLayer.startPoint = self.gradientStartPoint
        gradientLayer.endPoint = self.gradientEndPoint
        gradientLayer.frame = self.bounds
        if let topLayer = self.layer.sublayers?.first, topLayer is CAGradientLayer
        {
            topLayer.removeFromSuperlayer()
        }
        self.layer.addSublayer(gradientLayer)
    }
    
    
    
}

@IBDesignable
class Button: UIButton {
    override func layoutSubviews() {
        super.layoutSubviews()
        if cornerRadius == -1 {
            self.layer.cornerRadius = self.bounds.width < self.bounds.height ? self.bounds.width * 0.5 : self.bounds.height * 0.5
        }
    }
    
    @IBInspectable var gradientColor1: UIColor = UIColor.white {
        didSet{
            self.setGradient()
        }
    }
    
    @IBInspectable var gradientColor2: UIColor = UIColor.white {
        didSet{
            self.setGradient()
        }
    }
    
    @IBInspectable var gradientStartPoint: CGPoint = .zero {
        didSet{
            self.setGradient()
        }
    }
    
    @IBInspectable var gradientEndPoint: CGPoint = CGPoint(x: 0, y: 1) {
        didSet{
            self.setGradient()
        }
    }
    
    private func setGradient()
    {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [self.gradientColor1.cgColor, self.gradientColor2.cgColor]
        gradientLayer.startPoint = self.gradientStartPoint
        gradientLayer.endPoint = self.gradientEndPoint
        gradientLayer.frame = self.bounds
        if let topLayer = self.layer.sublayers?.first, topLayer is CAGradientLayer
        {
            topLayer.removeFromSuperlayer()
        }
        self.layer.addSublayer(gradientLayer)
    }
}

fileprivate class Keys {
    static let TOP_BORDER = "top-border"
    static let TOP_BORDER_VIEW = "top-border-view"
}

extension UIView {
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return CGFloat(tag)
        }
        set {
            layer.cornerRadius = newValue
            tag = Int(newValue)
            if newValue == -1 {
                self.clipsToBounds = true
                self.layer.cornerRadius = self.bounds.width < self.bounds.height ? self.bounds.width * 0.5 : self.bounds.height * 0.5
            } else {
                layer.masksToBounds = true
            }
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
    
    @IBInspectable var topBorder: Bool {
        get {
            if self.layer.value(forKey: Keys.TOP_BORDER) != nil {
                return self.layer.value(forKey: Keys.TOP_BORDER) as! Bool
            }
            
            return false
        }
        set {
            self.layer.setValue(newValue, forKey: Keys.TOP_BORDER)
        }
    }
    @IBInspectable var shadowColor: UIColor? {
        get {
            return UIColor(cgColor: layer.shadowColor!)
        }
        set {
            layer.shadowColor = newValue?.cgColor
        }
    }
    
    @IBInspectable var shadowOpacity: Float {
        get {
            return layer.shadowOpacity
        }
        set {
            layer.shadowOpacity = newValue
        }
    }
    @IBInspectable var shadowOffset: CGSize {
        get {
            return layer.shadowOffset
        }
        set {
            layer.shadowOffset = newValue
        }
    }
    @IBInspectable var shadowRadius: CGFloat {
        get {
            return layer.shadowRadius
        }
        set {
            layer.shadowRadius = newValue
        }
    }
    
    @IBInspectable var bottomBorderWidth: CGFloat {
        get {
            return 0.0   // Just to satisfy property
        }
        set {
            let border = UIView()
            border.backgroundColor = UIColor.white
            border.frame = CGRect(x: 0.0, y: bounds.size.height, width: bounds.size.width, height: newValue)
            border.translatesAutoresizingMaskIntoConstraints = false
            border.tag = 100
            self.addSubview(border)
            let views = ["line": border]
            
            let metrics = ["lineWidth": newValue]
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[line]|", options: [], metrics: nil, views: views))
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[line(==lineWidth)]|", options: [], metrics: metrics, views: views))
        }
    }
}

