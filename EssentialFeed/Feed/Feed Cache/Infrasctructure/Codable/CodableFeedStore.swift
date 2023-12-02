//
//  CodableFeedStore.swift
//  Feed
//
//  Created by Juan Santiago Martín Balbás on 20/8/23.
//

import Foundation

public final class CodableFeedStore: FeedStore {
    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date

        var localFeed: [LocalFeedImage] {
            feed.map { $0.local }
        }
    }

    private struct CodableFeedImage: Codable {
        let id: UUID
        let description: String?
        let location: String?
        let url: URL

        init(_ image: LocalFeedImage) {
            id = image.id
            description = image.description
            location = image.location
            url = image.url
        }

        var local: LocalFeedImage {
            LocalFeedImage(id: id, description: description, location: location, url: url)
        }
    }

    private let storeURL: URL

    public init(storeURL: URL) {
        self.storeURL = storeURL
    }

    public func retrieve() throws -> CachedFeed? {
        guard let data = try? Data(contentsOf: storeURL) else {
            return nil
        }

        let decoder = JSONDecoder()
        let cache = try decoder.decode(Cache.self, from: data)
        return CachedFeed(feed: cache.localFeed, timestamp: cache.timestamp)
    }

    public func insert(_ feed: [LocalFeedImage], timestamp: Date) throws {
        let encoder = JSONEncoder()
        let cache = Cache(feed: feed.map(CodableFeedImage.init), timestamp: timestamp)
        let encoded = try! encoder.encode(cache)
        try encoded.write(to: storeURL)
    }

    public func deleteCachedFeed() throws {
        guard FileManager.default.fileExists(atPath: storeURL.path) else {
            return
        }
        try FileManager.default.removeItem(at: storeURL)
    }
}
