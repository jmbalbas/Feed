//
//  CacheFeedImageDataUseCaseTests.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 2/11/23.
//

import Feed
import XCTest

final class CacheFeedImageDataUseCaseTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()

        XCTAssert(store.receivedMessages.isEmpty)
    }

    func test_saveImageDataForURL_requestsImageDataInsertionForURL() {
        let (sut, store) = makeSUT()
        let url = anyURL
        let data = anyData

        sut.save(data, for: url) { _ in }

        XCTAssertEqual(store.receivedMessages, [.insert(data: data, for: url)])
    }
}

private extension CacheFeedImageDataUseCaseTests {
    func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedImageDataLoader, store: FeedImageDataStoreSpy) {
        let store = FeedImageDataStoreSpy()
        let sut = LocalFeedImageDataLoader(store: store)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
}
