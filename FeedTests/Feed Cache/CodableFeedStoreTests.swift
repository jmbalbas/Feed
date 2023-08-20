//
//  CodableFeedStoreTests.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 10/8/23.
//

import Feed
import XCTest

protocol FeedStoreSpecs {
    func test_retrieve_deliversEmptyOnEmptyCache() async throws
    func test_retrieve_hasNoSideEffectsOnEmptyCache() async throws
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() async throws
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() async throws

    func test_insert_deliversNoErrorOnEmptyCache() async throws
    func test_insert_deliversNoErrorOnNonEmptyCache() async throws
    func test_insert_overridesPreviouslyInsertedCacheValues() async throws

    func test_delete_hasNoSideEffectsOnEmptyCache() async throws
    func test_delete_deliversNoErrorOnNonEmptyCache() async throws
    func test_delete_emptiesPreviouslyInsertedCache() async throws

    func test_storeSideEffects_runSerially() async throws
}

protocol FailableRetrieveFeedStoreSpecs {
    func test_retrieve_deliversFailureOnRetrievalError() async throws
    func test_retrieve_hasNoSideEffectsOnFailure() async throws
}

protocol FailableInsertFeedStoreSpecs {
    func test_insert_deliversFailureOnInsertionError() async throws
    func test_insert_hasNoSideEffectsOnInsertionError() async throws
}

protocol FailableDeleteFeedStoreSpecs {
    func test_delete_deliversErrorOnDeletionError() async throws
    func test_delete_hasNoSideEffectsOnDeletionError() async throws
}

final class CodableFeedStoreTests: XCTestCase {
    override func setUp() {
        super.setUp()
        setupEmptyStoreState()
    }
    
    override func tearDown() {
        undoStoreSideEffects()
        super.tearDown()
    }
    
    func test_retrieve_deliversEmptyOnEmptyCache() async throws {
        let sut = makeSUT()
        
        await expect(sut, toRetrieve: .empty)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() async throws {
        let sut = makeSUT()
        
        await expect(sut, toRetrieveTwice: .empty)
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() async throws {
        let sut = makeSUT()
        let feed = uniqueImageFeed.local
        let timestamp = Date()
        
        try await insert((feed, timestamp), to: sut)
        
        await expect(sut, toRetrieve: .found(feed: feed, timestamp: timestamp))
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() async throws {
        let sut = makeSUT()
        let feed = uniqueImageFeed.local
        let timestamp = Date()
        
        try await insert((feed, timestamp), to: sut)

        await expect(sut, toRetrieveTwice: .found(feed: feed, timestamp: timestamp))
    }
    
    func test_retrieve_deliversFailureOnRetrievalError() async throws {
        let storeURL = testSpecificStoreURL
        let sut = makeSUT(storeURL: storeURL)

        try "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        await expect(sut, toRetrieve: .failure(anyNSError))
    }
    
    func test_retrieve_hasNoSideEffectsOnFailure() async throws {
        let storeURL = testSpecificStoreURL
        let sut = makeSUT(storeURL: storeURL)

        try "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        await expect(sut, toRetrieveTwice: .failure(anyNSError))
    }

    func test_insert_deliversNoErrorOnEmptyCache() async throws {
        let sut = makeSUT()

        await XCTAssertNoThrow(try await insert((uniqueImageFeed.local, Date()), to: sut))
    }

    func test_insert_deliversNoErrorOnNonEmptyCache() async throws {
        let sut = makeSUT()
        try await insert((uniqueImageFeed.local, Date()), to: sut)

        await XCTAssertNoThrow(try await insert((uniqueImageFeed.local, Date()), to: sut), "Expected to override cache successfully")
    }

    func test_insert_overridesPreviouslyInsertedCacheValues() async throws {
        let sut = makeSUT()
        try await insert((uniqueImageFeed.local, Date()), to: sut)

        let latestFeed = uniqueImageFeed.local
        let latestTimestamp = Date()
        try await insert((latestFeed, latestTimestamp), to: sut)

        await expect(sut, toRetrieve: .found(feed: latestFeed, timestamp: latestTimestamp))
    }

    func test_insert_deliversFailureOnInsertionError() async throws {
        let invalidStoreURL = URL(string: "invalid://store-url")
        let sut = makeSUT(storeURL: invalidStoreURL)
        let feed = uniqueImageFeed.local
        let timestamp = Date()

        await XCTAssertThrowsError(try await insert((feed, timestamp), to: sut), "Expected cache insertion to fail with an error")
    }

    func test_insert_hasNoSideEffectsOnInsertionError() async throws {
        let invalidStoreURL = URL(string: "invalid://store-url")
        let sut = makeSUT(storeURL: invalidStoreURL)
        let feed = uniqueImageFeed.local
        let timestamp = Date()

        try? await insert((feed, timestamp), to: sut)

        await expect(sut, toRetrieve: .empty)
    }
    
    func test_delete_hasNoSideEffectsOnEmptyCache() async throws {
        let sut = makeSUT()
        
        try await deleteCache(from: sut)

        await expect(sut, toRetrieve: .empty)
    }

    func test_delete_deliversNoErrorOnNonEmptyCache() async throws {
        let sut = makeSUT()
        try await insert((uniqueImageFeed.local, Date()), to: sut)

        await XCTAssertNoThrow(try await deleteCache(from: sut), "Expected non-empty cache deletion to succeed")
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() async throws {
        let sut = makeSUT()
        try await insert((uniqueImageFeed.local, Date()), to: sut)
        
        try await deleteCache(from: sut)
        
        await expect(sut, toRetrieve: .empty)
    }

    func test_delete_deliversErrorOnDeletionError() async throws {
        let noDeletePermissionURL = cachesDirectory
        let sut = makeSUT(storeURL: noDeletePermissionURL)

        await XCTAssertThrowsError(try await deleteCache(from: sut), "Expected cache deletion to fail")
    }

    func test_delete_hasNoSideEffectsOnDeletionError() async throws {
        let noDeletePermissionURL = cachesDirectory
        let sut = makeSUT(storeURL: noDeletePermissionURL)

        try? await deleteCache(from: sut)

        await expect(sut, toRetrieve: .empty)
    }

    func test_storeSideEffects_runSerially() async throws {
        let sut = makeSUT()
        var completedOperationsInOrder: [XCTestExpectation] = []

        let op1 = expectation(description: "Operation 1")
        sut.insert(uniqueImageFeed.local, timestamp: Date()) { _ in
            completedOperationsInOrder.append(op1)
            op1.fulfill()
        }

        let op2 = expectation(description: "Operation 2")
        sut.deleteCachedFeed { _ in
            completedOperationsInOrder.append(op2)
            op2.fulfill()
        }

        let op3 = expectation(description: "Operation 3")
        sut.insert(uniqueImageFeed.local, timestamp: Date()) { _ in
            completedOperationsInOrder.append(op3)
            op3.fulfill()
        }

        await fulfillment(of: [op1, op2, op3])
        XCTAssertEqual(completedOperationsInOrder, [op1, op2, op3], "Expected side-effects to run serially but operations finished in the wrong order")
    }
}

private extension CodableFeedStoreTests {
    var testSpecificStoreURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appending(path: "\(type(of: self)).store")
    }

    var cachesDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }

    func makeSUT(storeURL: URL? = nil, file: StaticString = #file, line: UInt = #line) -> FeedStore {
        let sut = CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }
    
    func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }
    
    func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL)
    }
    
    func expect(
        _ sut: FeedStore,
        toRetrieve expectedResult: RetrieveCachedFeedResult,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        let exp = expectation(description: "Wait for cache retrieval")

        sut.retrieve { retrievedResult in
            switch (expectedResult, retrievedResult) {
            case (.empty, .empty), (.failure, .failure):
                break
            case let (.found(expectedFeed, expectedTimestamp), .found(retrievedFeed, retrievedTimestamp)):
                XCTAssertEqual(retrievedFeed, expectedFeed, file: file, line: line)
                XCTAssertEqual(retrievedTimestamp, expectedTimestamp, file: file, line: line)
            default:
                XCTFail("Expected to retrieve \(expectedResult), got \(retrievedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }

        await fulfillment(of: [exp], timeout: 1.0)
    }
    
    func expect(
        _ sut: FeedStore,
        toRetrieveTwice expectedResult: RetrieveCachedFeedResult,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        await expect(sut, toRetrieve: expectedResult, file: file, line: line)
        await expect(sut, toRetrieve: expectedResult, file: file, line: line)
    }
    
    func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: FeedStore) async throws {
        let exp = expectation(description: "Wait for cache insertion")
        var insertionError: Error?
        sut.insert(cache.feed, timestamp: cache.timestamp) { receivedInsertionError in
            insertionError = receivedInsertionError
            exp.fulfill()
        }
        await fulfillment(of: [exp], timeout: 1.0)
        try insertionError.map { throw $0 }
    }
    
    func deleteCache(from sut: FeedStore) async throws {
        let exp = expectation(description: "Wait for cache deletion")
        var deletionError: Error?
        sut.deleteCachedFeed { receivedDeletionError in
            deletionError = receivedDeletionError
            exp.fulfill()
        }
        await fulfillment(of: [exp], timeout: 3.0)
        try deletionError.map { throw $0 }
    }
}
