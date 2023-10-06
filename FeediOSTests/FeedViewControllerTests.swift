//
//  FeedViewControllerTests.swift
//  FeediOSTests
//
//  Created by Juan Santiago Martín Balbás on 6/10/23.
//

import Combine
import Feed
import Foundation
import UIKit
import XCTest

class FeedViewController: UIViewController {
    private var loader: FeedLoader?

    convenience init(loader: FeedLoader) {
        self.init()
        self.loader = loader
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        Task {
            try? await loader?.load()
        }
    }
}

@MainActor
final class FeedViewControllerTests: XCTestCase {
    func test_init_doesNotLoadFeed() {
        let (_, loader) = makeSUT()

        XCTAssertEqual(loader.loadCallCount, 0)
    }

    func test_viewDidLoad_loadsFeed() async {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()

        await assert(publisher: loader.$loadCallCount, equals: 1)
    }
}

private extension FeedViewControllerTests {
    func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: FeedViewController, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader)
    }
}

class LoaderSpy: FeedLoader {
    @Published private(set) var loadCallCount = 0

    func load() async throws -> [FeedImage] {
        loadCallCount += 1
        return []
    }
}
