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
        let loader = LoaderSpy()
        _ = FeedViewController(loader: loader)

        XCTAssertEqual(loader.loadCallCount, 0)
    }

    func test_viewDidLoad_loadsFeed() async {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)

        sut.loadViewIfNeeded()

        await assert(publisher: loader.$loadCallCount, equals: 1)
    }
}

private extension FeedViewControllerTests {
    func assert<E: Equatable>(
        publisher: Published<E>.Publisher,
        equals expectedValue: E,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        let expectation = expectation(description: "Changes to expected value")
        var cancellable: AnyCancellable?
        var currentValue: E?
        cancellable = publisher.sink { newValue in
            currentValue = newValue
            if newValue == expectedValue {
                expectation.fulfill()
                cancellable?.cancel()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 1)
        if currentValue != expectedValue {
            XCTFail("Expected \(expectedValue), got \(String(describing: currentValue))", file: file, line: line)
        }
    }
}

class LoaderSpy: FeedLoader {
    @Published private(set) var loadCallCount = 0

    func load() async throws -> [FeedImage] {
        loadCallCount += 1
        return []
    }
}
