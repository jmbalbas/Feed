//
//  CacheFeedUseCase.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 10/1/23.
//

import Foundation
import XCTest
import Feed

class FeedStore {
    private(set) var deleteCachedFeedCallCount: Int = 0

    func deleteCachedFeed() {
        deleteCachedFeedCallCount += 1
    }
}

class LocalFeedStore {
    private let store: FeedStore

    init(store: FeedStore) {
        self.store = store
    }

    func save(_ items: [FeedItem]) {
        store.deleteCachedFeed()
    }
}

class CacheFeedUseCase: XCTestCase {

    func test_init_doesNotDeleteCacheUponCreation() {
        let (_, store) = givenSUT()

        XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
    }

    func test_save_requestsCacheDeletion() {
        let (sut, store) = givenSUT()
        let items: [FeedItem] = [uniqueItem, uniqueItem]

        sut.save(items)

        XCTAssertEqual(store.deleteCachedFeedCallCount, 1)
    }
}

private extension CacheFeedUseCase {

    var uniqueItem: FeedItem {
        FeedItem(id: UUID(), description: nil, location: nil, imageURL: anyURL)
    }

    var anyURL: URL {
        URL(string: "http://any-url.com")!
    }

    func givenSUT() -> (sut: LocalFeedStore, store: FeedStore) {
        let store = FeedStore()
        return (LocalFeedStore(store: store), store)
    }
}
