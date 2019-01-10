//
//  CKLocalization.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/10/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKLocalization: NSObject {
    
    public class func string(byKey key: String) -> String {
        return NSLocalizedString(key, tableName: "ClearKeep", bundle: Bundle.main, value: "", comment: "")
    }
}

extension String {
    public static func ck_LocalizedString(key: String) -> String {
        return NSLocalizedString(key, tableName: "ClearKeep", bundle: Bundle.main, value: "", comment: "")
    }
}
