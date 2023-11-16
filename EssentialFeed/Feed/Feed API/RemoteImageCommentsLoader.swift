//
//  RemoteImageCommentsLoader.swift
//  Feed
//
//  Created by Juan Santiago Martín Balbás on 16/11/23.
//

import Foundation

public final class RemoteImageCommentsLoader: FeedLoader {
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
        client.get(from: url) { result in
            switch result {
            case let .success((data, response)):
                do {
                    let feed = try Self.map(data, from: response)
                    completion(.success(feed))
                } catch {
                    completion(.failure(error))
                }
            case .failure:
                completion(.failure(Errors.connectivity))
            }
        }
    }

    private static func map(_ data: Data, from response: HTTPURLResponse) throws -> [FeedImage] {
        try ImageCommentsMapper.map(data, from: response).toModels
    }
}

private extension Array where Element == RemoteFeedItem {
    var toModels: [FeedImage] {
        map { FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.image) }
    }
}

