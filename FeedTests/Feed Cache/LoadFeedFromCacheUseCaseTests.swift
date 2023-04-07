//
//  LoadFeedFromCacheUseCaseTests.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 7/2/23.
//

import XCTest
import Feed

class LoadFeedFromCacheUseCaseTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = givenSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }

    func test_load_requestsCacheRetrieval() {
        let (sut, store) = givenSUT()

        sut.load() { _ in }

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_load_failsOnRetrievalError() {
        let (sut, store) = givenSUT()
        let retrievalError = anyNSError
        let exp = expectation(description: "Wait for load completion")

        var receivedError: Error?
        sut.load { result in
            switch result {
            case .failure(let error):
                receivedError = error
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
            exp.fulfill()
        }
        store.completeRetrieval(with: retrievalError)

        waitForExpectations(timeout: 0.3)
        XCTAssertEqual(receivedError as? NSError, retrievalError)
    }
}

private extension LoadFeedFromCacheUseCaseTests {

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
