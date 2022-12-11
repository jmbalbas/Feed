//
//  RemoteFeedLoader.swift
//  Feed
//
//  Created by Juan Santiago Martín Balbás on 4/12/22.
//

import Foundation

public final class RemoteFeedLoader {
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

        do {
            return try FeedItemsMapper.map(data, response)
        } catch {
            throw Error.invalidData
        }
    }
}

private enum FeedItemsMapper {
    private struct Root: Decodable {
        let items: [Item]
    }

    private struct Item: Decodable {
        let id: UUID
        let description: String?
        let location: String?
        let image: URL

        var item: FeedItem {
            FeedItem(id: id, description: description, location: location, imageURL: image)
        }
    }

    private enum C {
        static let ok200 = 200
    }

    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [FeedItem] {
        guard response.statusCode == C.ok200 else {
            throw RemoteFeedLoader.Error.invalidData
        }
        return try JSONDecoder().decode(Root.self, from: data).items.map(\.item)
    }
}

