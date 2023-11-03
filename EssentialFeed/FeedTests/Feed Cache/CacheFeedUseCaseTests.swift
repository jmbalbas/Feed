//
//  CacheFeedUseCaseTests.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 10/1/23.
//

import Foundation
import XCTest
import Feed

class CacheFeedUseCaseTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = givenSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }

    func test_save_requestsCacheDeletion() {
        let (sut, store) = givenSUT()

        sut.save(uniqueImageFeed.models) { _ in }

        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }

    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = givenSUT()
        let deletionError = anyNSError

        sut.save(uniqueImageFeed.models) { _ in }
        store.completeDeletion(with: deletionError)

        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }

    func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
        let timestamp = Date()
        let (sut, store) = givenSUT(currentDate: { timestamp })
        let feed = uniqueImageFeed

        sut.save(feed.models) { _ in }
        store.completeDeletionSuccessfully()

        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed, .insert(feed.local, timestamp)])
    }

    func test_save_failsOnDeletionError() {
        let (sut, store) = givenSUT()
        let deletionError = anyNSError

        expect(sut, toCompleteWithError: deletionError, when: {
            store.completeDeletion(with: deletionError)
        })
    }

    func test_save_failsOnInsertionError() {
        let (sut, store) = givenSUT()
        let insertionError = anyNSError

        expect(sut, toCompleteWithError: insertionError, when: {
            store.completeDeletionSuccessfully()
            store.completeInsertion(with: insertionError)
        })
    }

    func test_save_succeedsOnSuccessfulCacheInsertion() {
        let (sut, store) = givenSUT()

        expect(sut, toCompleteWithError: nil, when: {
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        })
    }

    func test_save_doesNotDeliverDeletionErrorAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)

        var receivedResults: [LocalFeedLoader.SaveResult] = []
        sut?.save(uniqueImageFeed.models) { receivedResults.append($0) }

        sut = nil
        store.completeDeletion(with: anyNSError)

        XCTAssert(receivedResults.isEmpty)
    }

    func test_save_doesNotDeliverInsertionErrorAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)

        var receivedResults: [LocalFeedLoader.SaveResult] = []
        sut?.save(uniqueImageFeed.models) { receivedResults.append($0) }

        store.completeDeletionSuccessfully()
        sut = nil
        store.completeInsertion(with: anyNSError)

        XCTAssert(receivedResults.isEmpty)
    }
}

private extension CacheFeedUseCaseTests {

    func givenSUT(
        currentDate: @escaping () -> Date = Date.init,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(store, file: file, line: line)
        return (sut, store)
    }

    func expect(
        _ sut: LocalFeedLoader,
        toCompleteWithError expectedError: NSError?,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expectation = expectation(description: "Wait for save completion")
        var receivedError: Error?

        sut.save(uniqueImageFeed.models) { result in
            if case let .failure(error) = result {
                receivedError = error
            }
            expectation.fulfill()
        }

        action()

        waitForExpectations(timeout: 1)
        XCTAssertEqual(receivedError as? NSError, expectedError, file: file, line: line)
    }
}
