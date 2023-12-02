//
//  FeedStore.swift
//  Feed
//
//  Created by Juan Santiago Martín Balbás on 18/1/23.
//

import Foundation

public struct CachedFeed: Equatable {
    public let feed: [LocalFeedImage]
    public let timestamp: Date

    public init(feed: [LocalFeedImage], timestamp: Date) {
        self.feed = feed
        self.timestamp = timestamp
    }
}

public protocol FeedStore {
    func deleteCachedFeed() throws
    func insert(_ feed: [LocalFeedImage], timestamp: Date) throws
    func retrieve() throws -> CachedFeed?
}
