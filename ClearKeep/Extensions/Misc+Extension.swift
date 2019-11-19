//
//  Misc+Extension.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/25/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

extension MXKTableViewCell {

    // MARK: - CLASS VAR
    class var className: String {
        return String(describing: self)
    }
    
    // MARK: - CLASS OVERRIDEABLE
    
    open class var identifier: String {
        return self.nibName
    }
    
    open class var nibName: String {
        return self.className
    }
    
    class var nib: UINib {
        return UINib.init(nibName: self.nibName, bundle: nil)
    }
}

extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
    
    func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: self)
    }
    
    var firstName: String {
        
        // trim space before components
        var component = self.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: " ")
        
        if component.isEmpty { return self }
        
        return component[0]
    }
}

@objc
extension UIView {
    func applyGradient(colours: [UIColor]) -> Void {
        self.applyGradient(colours: colours, locations: nil)
    }
    
    func applyGradient(colours: [UIColor], locations: [NSNumber]?) -> Void {
        let name = "ck-gradient"
        
        self.layer.sublayers?.filter({ $0.name == name }).forEach({ (gradientLayer) in
            gradientLayer.removeFromSuperlayer()
        })
        
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.name = name
        gradient.frame = self.bounds
        gradient.colors = colours.map { $0.cgColor }
        gradient.locations = locations
        self.layer.insertSublayer(gradient, at: 0)
    }
}

extension MXRoomState {
    
    /**
     Try to get created of Date
     */
    var createdDate: Date? {
        
        // loop via rse
        for rev in self.stateEvents {
            
            // is room create event
            if rev.eventType == __MXEventTypeRoomCreate {
                
                // found created date
                return Date(timeIntervalSince1970: TimeInterval(rev.originServerTs / 1000)) // CK 301: Get origin time sever
            }
        }
        
        // not found
        return nil
    }
    
    /**
     Try to get creator
     */
    
    var creator: String? {

        // loop via rse
        for rev in self.stateEvents {
            
            // is room create event
            if rev.eventType == __MXEventTypeRoomCreate {
                
                // found creator
                if let createContent = MXRoomCreateContent(fromJSON: rev.content) {
                    return createContent.creatorUserId
                }
                
                // not found
                return "@unknown"
            }
        }
        
        // not found
        return nil
    }

}

extension MXEvent {
    var date: Date {
        return Date(timeIntervalSince1970: TimeInterval(self.ageLocalTs / 1000))
    }
}

extension String {
    public var int: Int? {
        return Int(self)
    }
    
    func base64Encoded() -> String? {
        return data(using: .utf8)?.base64EncodedString()
    }
    
    func base64Decoded() -> String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    func rawBase64Decoded() -> Data? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }
        return data
    }
}

extension UITableView {
    
    func scrollToBottom(_ adjustOffset: CGFloat = 53) {
        
        let offsetY: CGFloat = self.contentSize.height - self.bounds.size.height + self.contentInset.bottom + adjustOffset
        
        self.setContentOffset(CGPoint(x: 0, y: offsetY), animated: false)
    }
}


extension UINavigationBar {
    
    func hideShadow(_ value: Bool = true) {
        setValue(value, forKey: "hidesShadow")
    }
    
    
    func clearNavigationBar() {
        hideShadow()
        setBackgroundImage(UIImage(), for: .default)
        backgroundColor = .clear
    }
}
