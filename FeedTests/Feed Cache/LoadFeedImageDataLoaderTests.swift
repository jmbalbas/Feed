//
//  LoadFeedImageDataLoaderTests.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 2/11/23.
//

import Feed
import XCTest

final class LocalFeedImageDataLoader {
    init(store: Any) {

    }
}

final class LocalFeedImageDataLoaderTests: XCTestCase {
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()

        XCTAssert(store.receivedMessages.isEmpty)
    }
}

private extension LocalFeedImageDataLoaderTests {
    func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedImageDataLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedImageDataLoader(store: store)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }

    class FeedStoreSpy {
        let receivedMessages = [Any]()
    }
}
