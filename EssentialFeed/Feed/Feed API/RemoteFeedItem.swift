//
//  RemoteFeedItem.swift
//  Feed
//
//  Created by Juan Santiago Martín Balbás on 28/1/23.
//

import Foundation

struct RemoteFeedItem: Decodable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL
}
