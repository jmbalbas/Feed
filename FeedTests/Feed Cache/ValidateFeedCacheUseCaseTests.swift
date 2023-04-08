//
//  ValidateFeedCacheUseCaseTests.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 8/4/23.
//

import XCTest
import Feed

final class ValidateFeedCacheUseCaseTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = givenSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }


    func test_validateCache_deletesCacheOnRetrievalError() {
        let (sut, store) = givenSUT()

        sut.validateCache()
        store.completeRetrieval(with: anyNSError)

        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }
}

private extension ValidateFeedCacheUseCaseTests {

    var anyNSError: NSError {
        NSError(domain: "Any error", code: 1)
    }

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

}
