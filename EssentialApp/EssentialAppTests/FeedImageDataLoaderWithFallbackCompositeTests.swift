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
            let primaryLoader = LoaderSpy()
            let fallbackLoader = LoaderSpy()
            _ = FeedImageDataLoaderWithFallbackComposite(primary: primaryLoader, fallback: fallbackLoader)

            XCTAssert(primaryLoader.loadedURLs.isEmpty, "Expected no loaded URLs in the primary loader")
            XCTAssert(fallbackLoader.loadedURLs.isEmpty, "Expected no loaded URLs in the fallback loader")
        }
    }

    func test_loadImageData_loadsFromPrimaryLoaderFirst() {
        let url = anyURL
        let primaryLoader = LoaderSpy()
        let fallbackLoader = LoaderSpy()
        let sut = FeedImageDataLoaderWithFallbackComposite(primary: primaryLoader, fallback: fallbackLoader)

        _ = sut.loadImageData(from: url) { _ in }

        XCTAssertEqual(primaryLoader.loadedURLs, [url], "Expected to load URL from primary loader")
        XCTAssert(fallbackLoader.loadedURLs.isEmpty, "Expected no loaded URLs in the fallback loader")
    }
}

private extension FeedImageDataLoaderWithFallbackCompositeTests {
    var anyURL: URL {
        URL(string: "http://a-url.com")!
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
