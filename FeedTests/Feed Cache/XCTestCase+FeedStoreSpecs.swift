//
//  XCTestCase+FeedStoreSpecs.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 2/9/23.
//

import Feed
import XCTest

extension FeedStoreSpecs where Self: XCTestCase {
    func expect(
        _ sut: FeedStore,
        toRetrieve expectedResult: FeedStore.RetrievalResult,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        let exp = expectation(description: "Wait for cache retrieval")

        sut.retrieve { retrievedResult in
            switch (expectedResult, retrievedResult) {
            case (.success(.none), .success(.none)), (.failure, .failure):
                break
            case let (.success(expectedFeed), .success(retrievedFeed)):
                XCTAssertEqual(retrievedFeed, expectedFeed, file: file, line: line)
            default:
                XCTFail("Expected to retrieve \(expectedResult), got \(retrievedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }

        await fulfillment(of: [exp], timeout: 1.0)
    }

    func expect(
        _ sut: FeedStore,
        toRetrieveTwice expectedResult: FeedStore.RetrievalResult,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        await expect(sut, toRetrieve: expectedResult, file: file, line: line)
        await expect(sut, toRetrieve: expectedResult, file: file, line: line)
    }

    func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: FeedStore) async throws {
        let exp = expectation(description: "Wait for cache insertion")
        var insertionError: Error?
        sut.insert(cache.feed, timestamp: cache.timestamp) { receivedInsertionResult in
            if case let .failure(error) = receivedInsertionResult {
                insertionError = error
            }
            exp.fulfill()
        }
        await fulfillment(of: [exp], timeout: 1.0)
        try insertionError.map { throw $0 }
    }

    func deleteCache(from sut: FeedStore) async throws {
        let exp = expectation(description: "Wait for cache deletion")
        var deletionError: Error?
        sut.deleteCachedFeed { receivedDeletionResult in
            if case let .failure(error) = receivedDeletionResult {
                deletionError = error
            }
            exp.fulfill()
        }
        await fulfillment(of: [exp], timeout: 3.0)
        try deletionError.map { throw $0 }
    }
}
