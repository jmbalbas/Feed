//
//  NullStore.swift
//  EssentialApp
//
//  Created by Juan Santiago Martín Balbás on 30/11/23.
//

import Feed
import Foundation

final class NullStore {}

extension NullStore: FeedStore {
    func deleteCachedFeed() throws {}

    func insert(_ feed: [LocalFeedImage], timestamp: Date) throws {}

    func retrieve() throws -> CachedFeed? { .none }
}

extension NullStore: FeedImageDataStore {
    func insert(_ data: Data, for url: URL) throws {}

    func retrieve(dataForURL url: URL) throws -> Data? { .none }
}
