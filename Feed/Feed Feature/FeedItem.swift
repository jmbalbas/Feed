//
//  FeedItem.swift
//  Feed
//
//  Created by Juan Santiago Martín Balbás on 3/12/22.
//

import Foundation

public struct FeedItem: Equatable {
    let id: UUID
    let description: String?
    let location: String?
    let imageURL: URL
}
