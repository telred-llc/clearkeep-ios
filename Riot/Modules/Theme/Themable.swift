/*
 Copyright 2019 New Vector Ltd

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation
import UIKit

@objc protocol Themable: class {
    func update(theme: ThemeReaction)
}

@objcMembers
class ThemeService {
    
    static let shared: ThemeService = ThemeService()
    
    var theme: ThemeReaction! {
        didSet {
            NotificationCenter.default.post(name: .themeServiceDidChangeTheme, object: nil)
        }
    }
    
    private init() {
        setupTheme(.light)
    }
    
    func setupTheme(_ theme: ThemeType) {
        switch theme {
        case .light:
            self.theme = DefaultTheme()
        case .dark:
            self.theme = DarkThemeReaction()
        }
    }
}
