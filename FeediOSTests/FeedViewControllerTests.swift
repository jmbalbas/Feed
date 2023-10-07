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

class FeedViewController: UITableViewController {
    private var loader: FeedLoader?

    convenience init(loader: FeedLoader) {
        self.init()
        self.loader = loader
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)

        load()
    }

    @objc private func load() {
        Task {
            _ = try? await loader?.load()
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

    func test_pullToRefresh_reloadsFeed() async {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()

        sut.refreshControl?.simulatePullToRefresh()
        await assert(publisher: loader.$loadCallCount, equals: 2)

        sut.refreshControl?.simulatePullToRefresh()
        await assert(publisher: loader.$loadCallCount, equals: 3)
    }
}

private extension FeedViewControllerTests {
    func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: FeedViewController, loader: LoaderSpy) {
        let loader = LoaderSpy()
        return (FeedViewController(loader: loader), loader)
    }
}

@MainActor
class LoaderSpy: FeedLoader {
    @Published private(set) var loadCallCount = 0

    func load() async throws -> [FeedImage] {
        loadCallCount += 1
        return []
    }
}

private extension UIRefreshControl {
    func simulatePullToRefresh() {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: .valueChanged)?.forEach { action in
                (target as NSObject).perform(Selector(action))
            }
        }
    }
}
