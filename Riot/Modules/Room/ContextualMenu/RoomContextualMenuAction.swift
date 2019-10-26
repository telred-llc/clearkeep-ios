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

@objc enum RoomContextualMenuAction: Int {
    case copy
    case reply
    case edit
    case more
    
    // MARK: - Properties
    
    var title: String {
        let title: String
        
        switch self {
        case .copy:
            title = "room_event_action_copy".localized()
        case .reply:
            title = "room_event_action_reply".localized()
        case .edit:
            title = "room_event_action_edit".localized()
        case .more:
            title = "room_event_action_more".localized()
        }
        
        return title
    }
    
    var image: UIImage? {
        let image: UIImage?
        
        switch self {
        case .copy:
            image = UIImage(named: "room_context_menu_copy")
        case .reply:
            image = UIImage(named: "room_context_menu_reply")
        case .edit:
            image = UIImage(named: "room_context_menu_edit")
        case .more:
            image = UIImage(named: "room_context_menu_more")
        default:
            image = nil
        }
        
        return image
    }
}
