//
//  FeedLoaderWithFallbackCompositeTests.swift
//  EssentialAppTests
//
//  Created by Juan Santiago Martín Balbás on 3/11/23.
//  Copyright © 2023 Essential Developer. All rights reserved.
//

import Feed
import XCTest

final class FeedLoaderWithFallbackComposite: FeedLoader {
    private let primary: FeedLoader
    private let fallback: FeedLoader

    init(primary: FeedLoader, fallback: FeedLoader) {
        self.primary = primary
        self.fallback = fallback
    }

    func load(completion: @escaping (FeedLoader.Result) -> Void) {
        primary.load { [weak self] result in
            switch result {
            case .success:
                completion(result)
            case .failure:
                self?.fallback.load(completion: completion)
            }
        }
    }
}

final class FeedLoaderWithFallbackCompositeTests: XCTestCase {
    func test_load_deliversPrimaryFeedOnPrimaryLoaderSuccess() {
        let primaryFeed = uniqueFeed
        let fallbackFeed = uniqueFeed
        let sut = makeSUT(primaryResult: .success(primaryFeed), fallbackResult: .success(fallbackFeed))

        let exp = expectation(description: "Wait for load completion")
        sut.load { result in
            switch result {
            case let .success(feed):
                XCTAssertEqual(feed, primaryFeed)
            case .failure:
                XCTFail("Expected successful load feed result, got \(result) instead")
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)
    }

    func test_load_deliversFallbackFeedOnPrimaryLoaderFailure() {
        let fallbackFeed = uniqueFeed
        let sut = makeSUT(primaryResult: .failure(anyNSError), fallbackResult: .success(fallbackFeed))

        let exp = expectation(description: "Wait for load completion")

        sut.load { result in
            switch result {
            case let .success(receivedFeed):
                XCTAssertEqual(receivedFeed, fallbackFeed)

            case .failure:
                XCTFail("Expected successful load feed result, got \(result) instead")
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }
}

private extension FeedLoaderWithFallbackCompositeTests {
    var anyNSError: NSError {
        NSError(domain: "any error", code: 0)
    }

    var uniqueFeed: [FeedImage] {
        [FeedImage(id: UUID(), description: "Description", location: "Location", url: URL(string: "https://any-url.com")!)]
    }

    func makeSUT(
        primaryResult: FeedLoader.Result,
        fallbackResult: FeedLoader.Result,
        file: StaticString = #file,
        line: UInt = #line
    ) -> FeedLoader {
           let primaryLoader = LoaderStub(result: primaryResult)
           let fallbackLoader = LoaderStub(result: fallbackResult)
           let sut = FeedLoaderWithFallbackComposite(primary: primaryLoader, fallback: fallbackLoader)
           trackForMemoryLeaks(primaryLoader, file: file, line: line)
           trackForMemoryLeaks(fallbackLoader, file: file, line: line)
           trackForMemoryLeaks(sut, file: file, line: line)
           return sut
       }

       func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
           addTeardownBlock { [weak instance] in
               XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
           }
       }
}

private class LoaderStub: FeedLoader {
    private let result: FeedLoader.Result

    init(result: FeedLoader.Result) {
        self.result = result
    }

    func load(completion: @escaping (FeedLoader.Result) -> Void) {
        completion(result)
    }
}
