//
//  RemoteFeedLoader.swift
//  Feed
//
//  Created by Juan Santiago Martín Balbás on 4/12/22.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
    private let client: HTTPClient
    private let url: URL

    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    public init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }

    public func load() async throws -> [FeedItem] {
        guard let (data, response) = try? await client.get(from: url) else {
            throw Error.connectivity
        }

        return try Self.map(data, from: response)
    }

    private static func map(_ data: Data, from response: HTTPURLResponse) throws -> [FeedItem] {
        try FeedItemsMapper.map(data, from: response).toModels
    }
}

private extension Array where Element == RemoteFeedItem {
    var toModels: [FeedItem] {
        map { FeedItem(id: $0.id, description: $0.description, location: $0.location, imageURL: $0.image) }
    }
}
