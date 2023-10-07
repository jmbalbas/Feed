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

    public enum Errors: Error {
        case connectivity
        case invalidData
    }

    public init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }

    public func load(completion: @escaping (FeedLoader.Result) -> Void) {
        Task {
            do {
                let feed = try await load()
                completion(.success(feed))
            } catch {
                completion(.failure(error))
            }
        }
    }

    public func load() async throws -> [FeedImage] {
        guard let (data, response) = try? await client.get(from: url) else {
            throw Errors.connectivity
        }

        return try Self.map(data, from: response)
    }

    private static func map(_ data: Data, from response: HTTPURLResponse) throws -> [FeedImage] {
        try FeedItemsMapper.map(data, from: response).toModels
    }
}

private extension Array where Element == RemoteFeedItem {
    var toModels: [FeedImage] {
        map { FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.image) }
    }
}
