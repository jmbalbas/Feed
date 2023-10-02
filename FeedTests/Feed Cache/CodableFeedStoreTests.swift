//
//  CodableFeedStoreTests.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 10/8/23.
//

import Feed
import XCTest

final class CodableFeedStoreTests: XCTestCase, FailableFeedStore {
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
        
        await expect(sut, toRetrieve: .success(.none))
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() async throws {
        let sut = makeSUT()
        
        await expect(sut, toRetrieveTwice: .success(.none))
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() async throws {
        let sut = makeSUT()
        let feed = uniqueImageFeed.local
        let timestamp = Date()
        
        try await insert((feed, timestamp), to: sut)
        
        await expect(sut, toRetrieve: .success(CachedFeed(feed: feed, timestamp: timestamp)))
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() async throws {
        let sut = makeSUT()
        let feed = uniqueImageFeed.local
        let timestamp = Date()
        
        try await insert((feed, timestamp), to: sut)

        await expect(sut, toRetrieveTwice: .success(CachedFeed(feed: feed, timestamp: timestamp)))
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

        await expect(sut, toRetrieve: .success(CachedFeed(feed: latestFeed, timestamp: latestTimestamp)))
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

        await expect(sut, toRetrieve: .success(.none))
    }
    
    func test_delete_hasNoSideEffectsOnEmptyCache() async throws {
        let sut = makeSUT()
        
        try await deleteCache(from: sut)

        await expect(sut, toRetrieve: .success(.none))
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
        
        await expect(sut, toRetrieve: .success(.none))
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

        await expect(sut, toRetrieve: .success(.none))
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
        FileManager.default.urls(for: .cachesDirectory, in: .systemDomainMask).first!
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
}
