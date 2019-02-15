//
//  CKIndexedPagingItem.swift
//  Riot
//
//  Created by Pham Hoa on 2/15/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit
import Parchment

/// The `PagingTitleItem` protocol is used the `PagingTitleCell` to
/// store a title that is going to be display in the menu items.
public protocol PagingTitleAndBubbleItem: PagingItem {
    var title: String { get }
    var bubbleTitle: String? { get }
}

/// An implementation of the `PagingItem` protocol that stores the
/// index and title of a given item. The index property is needed to
/// make the `PagingItem` comparable. Used by default when using
/// `IndexedPagingViewController`.
public struct CKPagingIndexItem: PagingTitleAndBubbleItem, Equatable, Hashable, Comparable {

    /// The index of the `PagingItem` instance
    public let index: Int
    
    /// The title used in the menu cells.
    public let title: String

    /// The title used in the bubble
    public var bubbleTitle: String?

    public var hashValue: Int {
        return index
    }
    
    /// Creates an instance of `PagingIndexItem`
    ///
    /// Parameter index: The index of the `PagingItem`.
    /// Parameter title: The title used in the menu cells.
    public init(index: Int, title: String, bubbleTitle: String?) {
        self.title = title
        self.index = index
        self.bubbleTitle = bubbleTitle
    }
    
    public static func ==(lhs: CKPagingIndexItem, rhs: CKPagingIndexItem) -> Bool {
        return lhs.index == rhs.index && lhs.title == rhs.title && lhs.bubbleTitle == rhs.bubbleTitle
    }
    
    public static func <(lhs: CKPagingIndexItem, rhs: CKPagingIndexItem) -> Bool {
        return lhs.index < rhs.index
    }
}
