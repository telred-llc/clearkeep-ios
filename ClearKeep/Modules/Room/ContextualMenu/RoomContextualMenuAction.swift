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
            title = CKLocalization.string(byKey: "room_event_action_copy")
        case .reply:
            title = CKLocalization.string(byKey: "room_event_action_reply")
        case .edit:
            title = CKLocalization.string(byKey: "room_event_action_edit")
        case .more:
            title = CKLocalization.string(byKey: "room_event_action_more")
        }
        
        return title
    }
    
    var image: UIImage? {
        let image: UIImage?
        
        switch self {
        case .copy:
            image = #imageLiteral(resourceName: "room_context_menu_copy")
        case .reply:
            image = #imageLiteral(resourceName: "room_context_menu_reply")
        case .edit:
            image = #imageLiteral(resourceName: "room_context_menu_edit")
        case .more:
            image = #imageLiteral(resourceName: "room_context_menu_more")
        default:
            image = nil
        }
        
        return image
    }
}
