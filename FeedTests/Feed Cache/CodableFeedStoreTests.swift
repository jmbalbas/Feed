//
//  CodableFeedStoreTests.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 10/8/23.
//

import Feed
import XCTest

final class CodableFeedStore: FeedStore {
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
    
    init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    func retrieve(completion: @escaping RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        
        do {
            let decoder = JSONDecoder()
            let cache = try decoder.decode(Cache.self, from: data)
            completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
        } catch {
            completion(.failure(error))
        }
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        let encoder = JSONEncoder()
        let cache = Cache(feed: feed.map(CodableFeedImage.init), timestamp: timestamp)
        let encoded = try! encoder.encode(cache)
        do {
            try encoded.write(to: storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }

    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        guard FileManager.default.fileExists(atPath: storeURL.path) else {
            return completion(nil)
        }
        do {
            try FileManager.default.removeItem(at: storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }
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
    
    func test_retrieve_deliversEmptyOnEmptyCache() async {
        let sut = makeSUT()
        
        await expect(sut, toRetrieve: .empty)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() async {
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
    
    func test_retrieve_deliversFailureOnRetrievalError() async {
        let storeURL = testSpecificStoreURL
        let sut = makeSUT(storeURL: storeURL)

        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        await expect(sut, toRetrieve: .failure(anyNSError))
    }
    
    func test_retrieve_hasNoSideEffectsOnFailure() async {
        let storeURL = testSpecificStoreURL
        let sut = makeSUT(storeURL: storeURL)

        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        await expect(sut, toRetrieveTwice: .failure(anyNSError))
    }
    
    func test_insert_overridesPreviouslyInsertedCacheValues() async {
        let sut = makeSUT()

        await XCTAssertNoThrow(try await insert((uniqueImageFeed.local, Date()), to: sut), "Expected to insert cache successfully")

        let latestFeed = uniqueImageFeed.local
        let latestTimestamp = Date()
        await XCTAssertNoThrow(try await insert((latestFeed, latestTimestamp), to: sut), "Expected to override cache successfully")

        await expect(sut, toRetrieve: .found(feed: latestFeed, timestamp: latestTimestamp))
    }

    func test_insert_deliversFailureOnInsertionError() async {
        let invalidStoreURL = URL(string: "invalid://store-url")
        let sut = makeSUT(storeURL: invalidStoreURL)
        let feed = uniqueImageFeed.local
        let timestamp = Date()

        await XCTAssertThrowsError(try await insert((feed, timestamp), to: sut), "Expected cache insertion to fail with an error")
    }
    
    func test_delete_hasNoSideEffectsOnEmptyCache() async {
        let sut = makeSUT()
        
        await XCTAssertNoThrow(try await deleteCache(from: sut), "Expected non-empty cache deletion to succeed")

        await expect(sut, toRetrieve: .empty)
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() async throws {
        let sut = makeSUT()
        try await insert((uniqueImageFeed.local, Date()), to: sut)
        
        await XCTAssertNoThrow(try await deleteCache(from: sut), "Expected non-empty cache deletion to succeed")
        
        await expect(sut, toRetrieve: .empty)
    }

    func test_delete_deliversErrorOnDeletionError() async {
        let noDeletePermissionURL = cachesDirectory
        let sut = makeSUT(storeURL: noDeletePermissionURL)

        await XCTAssertThrowsError(try await deleteCache(from: sut), "Expected cache deletion to fail")

        await expect(sut, toRetrieve: .empty)
    }
}

private extension CodableFeedStoreTests {
    var testSpecificStoreURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appending(path: "\(type(of: self)).store")
    }

    var cachesDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }

    func makeSUT(storeURL: URL? = nil, file: StaticString = #file, line: UInt = #line) -> CodableFeedStore {
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
        _ sut: CodableFeedStore,
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
        _ sut: CodableFeedStore,
        toRetrieveTwice expectedResult: RetrieveCachedFeedResult,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        await expect(sut, toRetrieve: expectedResult, file: file, line: line)
        await expect(sut, toRetrieve: expectedResult, file: file, line: line)
    }
    
    func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: CodableFeedStore) async throws {
        let exp = expectation(description: "Wait for cache insertion")
        var insertionError: Error?
        sut.insert(cache.feed, timestamp: cache.timestamp) { receivedInsertionError in
            insertionError = receivedInsertionError
            exp.fulfill()
        }
        await fulfillment(of: [exp], timeout: 1.0)
        try insertionError.map { throw $0 }
    }
    
    func deleteCache(from sut: CodableFeedStore) async throws {
        let exp = expectation(description: "Wait for cache deletion")
        var deletionError: Error?
        sut.deleteCachedFeed { receivedDeletionError in
            deletionError = receivedDeletionError
            exp.fulfill()
        }
        await fulfillment(of: [exp], timeout: 1.0)
        try deletionError.map { throw $0 }
    }
}
