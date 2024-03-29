//
//  FeedItemsMapper.swift
//  Feed
//
//  Created by Juan Santiago Martín Balbás on 11/12/22.
//

import Foundation

public enum FeedItemsMapper {
    private struct Root: Decodable {
        private let items: [RemoteFeedItem]

        private struct RemoteFeedItem: Decodable {
            let id: UUID
            let description: String?
            let location: String?
            let image: URL
        }

        var images: [FeedImage] {
            items.map { FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.image) }
        }
    }

    public enum Errors: Error {
        case invalidData
    }

    public static func map(_ data: Data, from response: HTTPURLResponse) throws -> [FeedImage] {
        guard response.isOK, let root = try? JSONDecoder().decode(Root.self, from: data) else {
            throw Errors.invalidData
        }
        return root.images
    }
}
