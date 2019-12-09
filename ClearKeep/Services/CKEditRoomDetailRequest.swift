//
//  CKEditRoomDetailModel.swift
//  Riot
//
//  Created by ReasonLeveing on 11/12/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation
import PromiseKit

struct CKEditRoomDetailRequest {
    
    func editRoomDetail(mxRoom: MXRoom, displayName: String, topicName: String, image: UIImage?, completion: @escaping ((Error?) -> Void)) {
        
        firstly {
            when(fulfilled: self.editDisplayName(mxRoom: mxRoom, displayName: displayName)).then { _ in
                self.editTopicName(mxRoom: mxRoom, topicName: topicName).then { _ in
                    self.editAvatarRoom(mxRoom: mxRoom, image: image)
                }
            }
        }.done {
            completion(nil)
        }.catch { (error) in
            completion(error)
        }
    }
}

extension CKEditRoomDetailRequest {
    
    @discardableResult
    private func editDisplayName(mxRoom: MXRoom, displayName: String) -> Promise<Void> {
        
        return Promise { seal in
            mxRoom.summary.displayname = displayName
            mxRoom.setName(displayName) { (response) in
                
                switch response {
                case .success:
                    return seal.fulfill_()
                case .failure(let error):
                    return seal.reject(error)
                }
            }
        }
    }
    
    @discardableResult
    private func editTopicName(mxRoom: MXRoom, topicName: String) -> Promise<Void> {
        
        return Promise { seal in
            mxRoom.summary.topic = topicName
            mxRoom.setTopic(topicName) { (response) in
                
                switch response {
                case .success:
                    return seal.fulfill_()
                case .failure(let error):
                    return seal.reject(error)
                }
            }
        }
    }
    
    
    @discardableResult
    private func editAvatarRoom(mxRoom: MXRoom, image: UIImage?) -> Promise<Void> {

        return Promise { seal in
            
            if image == nil {
                return seal.fulfill_()
            }

            guard let updatedPicture = MXKTools.forceImageOrientationUp(image) else {
                return seal.reject(CKError.loadFailImage)
            }
            
            let uploader: MXMediaLoader? = MXMediaManager.prepareUploader(withMatrixSession: mxRoom.mxSession, initialRange: 0.0, andRange: 1.0)
            
            uploader?.uploadData(UIImageJPEGRepresentation(updatedPicture, 0.5),
                                 filename: nil,
                                 mimeType: "image/jpeg",
                                 success: { (result) in
                                    
                                    guard let url = URL(string: result ?? "") else {
                                        return seal.reject(CKError.unexpectedError)
                                    }
                                    
                                    mxRoom.setAvatar(url: url) { (response) in
                                        switch response {
                                        case .success:
                                            return seal.fulfill_()
                                        case .failure(let error):
                                            return seal.reject(error)
                                        }
                                    }
                                     
            }, failure: { (error) in
                return seal.reject(error ?? CKError.unexpectedError)
            })
        }
    }
    
}
