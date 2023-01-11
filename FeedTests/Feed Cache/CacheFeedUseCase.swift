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
    typealias DeletionCompletion = (Error?) -> Void
    private(set) var deleteCachedFeedCallCount: Int = 0
    private(set) var insertCallCount: Int = 0

    private var deletionCompletions: [DeletionCompletion] = []

    func deleteCachedFeed(completion: @escaping (Error?) -> Void) {
        deleteCachedFeedCallCount += 1
        deletionCompletions.append(completion)
    }

    func completeDeletion(with error: NSError, at index: Int = 0) {
        deletionCompletions[index](error)
    }

    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }

    func insert(_ items: [FeedItem]) {
        insertCallCount += 1
    }
}

class LocalFeedStore {
    private let store: FeedStore

    init(store: FeedStore) {
        self.store = store
    }

    func save(_ items: [FeedItem]) {
        store.deleteCachedFeed { [unowned self] error in
            if error == nil {
                self.store.insert(items)
            }
        }
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

    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = givenSUT()
        let items: [FeedItem] = [uniqueItem, uniqueItem]
        let deletionError = anyNSError

        sut.save(items)
        store.completeDeletion(with: deletionError)

        XCTAssertEqual(store.insertCallCount, 0)
    }

    func test_save_requestsNewCacheInsertionOnSuccessfulDeletion() {
        let (sut, store) = givenSUT()
        let items: [FeedItem] = [uniqueItem, uniqueItem]

        sut.save(items)
        store.completeDeletionSuccessfully()

        XCTAssertEqual(store.insertCallCount, 1)
    }
}

private extension CacheFeedUseCase {

    var uniqueItem: FeedItem {
        FeedItem(id: UUID(), description: nil, location: nil, imageURL: anyURL)
    }

    var anyURL: URL {
        URL(string: "http://any-url.com")!
    }

    var anyNSError: NSError {
        NSError(domain: "Any error", code: 1)
    }

    func givenSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedStore, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedStore(store: store)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(store, file: file, line: line)
        return (sut, store)
    }
}
