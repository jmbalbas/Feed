//
//  FeedItemsMapper.swift
//  Feed
//
//  Created by Juan Santiago Martín Balbás on 11/12/22.
//

import Foundation

enum FeedItemsMapper {
    private struct Root: Decodable {
        let items: [RemoteFeedItem]
    }

    private enum C {
        static let ok200 = 200
    }

    static func map(_ data: Data, from response: HTTPURLResponse) throws -> [RemoteFeedItem] {
        guard
            response.statusCode == C.ok200,
            let feed = try? JSONDecoder().decode(Root.self, from: data).items
        else {
            throw RemoteFeedLoader.Error.invalidData
        }
        return feed
    }
}

struct RemoteFeedItem: Decodable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL
}
