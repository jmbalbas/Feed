//
//  LoadFeedFromCacheUseCase.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 7/2/23.
//

import XCTest
import Feed

class LoadFeedFromCacheUseCase: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = givenSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }
}

private extension LoadFeedFromCacheUseCase {
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
