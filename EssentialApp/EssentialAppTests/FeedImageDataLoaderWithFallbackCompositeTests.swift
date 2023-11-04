//
//  FeedImageDataLoaderWithFallbackCompositeTests.swift
//  EssentialAppTests
//
//  Created by Juan Santiago Martín Balbás on 4/11/23.
//

import Feed
import XCTest

class FeedImageDataLoaderWithFallbackComposite: FeedImageDataLoader {
    private class Task: FeedImageDataLoaderTask {
        func cancel() {

        }
    }

    private let primary: FeedImageDataLoader

    init(primary: FeedImageDataLoader, fallback: FeedImageDataLoader) {
        self.primary = primary
    }

    func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result) -> Void) -> FeedImageDataLoaderTask {
        _ = primary.loadImageData(from: url) { _ in }
        return Task()
    }
}

private class FeedImageDataLoaderWithFallbackCompositeTests: XCTestCase {
    func test_init_doesNotLoadImageData() {
        func test_init_doesNotLoadImageData() {
            let (_, primaryLoader, fallbackLoader) = makeSUT()

            XCTAssert(primaryLoader.loadedURLs.isEmpty, "Expected no loaded URLs in the primary loader")
            XCTAssert(fallbackLoader.loadedURLs.isEmpty, "Expected no loaded URLs in the fallback loader")
        }
    }

    func test_loadImageData_loadsFromPrimaryLoaderFirst() {
        let url = anyURL
        let (sut, primaryLoader, fallbackLoader) = makeSUT()

        _ = sut.loadImageData(from: url) { _ in }

        XCTAssertEqual(primaryLoader.loadedURLs, [url], "Expected to load URL from primary loader")
        XCTAssert(fallbackLoader.loadedURLs.isEmpty, "Expected no loaded URLs in the fallback loader")
    }
}

private extension FeedImageDataLoaderWithFallbackCompositeTests {
    var anyURL: URL {
        URL(string: "http://a-url.com")!
    }

    func makeSUT(
        file: StaticString = #file,
        line: UInt = #line
    ) -> (sut: FeedImageDataLoader, primary: LoaderSpy, fallback: LoaderSpy) {
        let primaryLoader = LoaderSpy()
        let fallbackLoader = LoaderSpy()
        let sut = FeedImageDataLoaderWithFallbackComposite(primary: primaryLoader, fallback: fallbackLoader)
        trackForMemoryLeaks(primaryLoader, file: file, line: line)
        trackForMemoryLeaks(fallbackLoader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, primaryLoader, fallbackLoader)
    }

    func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
        }
    }
}

private class LoaderSpy: FeedImageDataLoader {
    private var messages: [(url: URL, completion: (FeedImageDataLoader.Result) -> Void)] = []

    var loadedURLs: [URL] {
        messages.map { $0.url }
    }

    private struct Task: FeedImageDataLoaderTask {
        func cancel() {}
    }

    func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result) -> Void) -> FeedImageDataLoaderTask {
        messages.append((url, completion))
        return Task()
    }
}
