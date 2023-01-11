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
    private(set) var insertCalls: [(items: [FeedItem], timestamp: Date)] = []

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

    func insert(_ items: [FeedItem], timestamp: Date) {
        insertCallCount += 1
        insertCalls.append((items: items, timestamp: timestamp))
    }
}

class LocalFeedStore {
    private let store: FeedStore
    private let currentDate: () -> Date

    init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }

    func save(_ items: [FeedItem]) {
        store.deleteCachedFeed { [unowned self] error in
            if error == nil {
                self.store.insert(items, timestamp: currentDate())
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

    func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
        let timestamp = Date()
        let (sut, store) = givenSUT(currentDate: { timestamp })
        let items: [FeedItem] = [uniqueItem, uniqueItem]

        sut.save(items)
        store.completeDeletionSuccessfully()

        XCTAssertEqual(store.insertCallCount, 1)
        let insertion = store.insertCalls.first
        XCTAssertEqual(insertion?.items, items)
        XCTAssertEqual(insertion?.timestamp, timestamp)
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

    func givenSUT(
        currentDate: @escaping () -> Date = Date.init,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: LocalFeedStore, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedStore(store: store, currentDate: currentDate)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(store, file: file, line: line)
        return (sut, store)
    }
}
