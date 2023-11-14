//
//  SceneDelegateTests.swift
//  EssentialAppTests
//
//  Created by Juan Santiago Martín Balbás on 8/11/23.
//

@testable import EssentialApp
import FeediOS
import XCTest

class SceneDelegateTests: XCTestCase {
    func test_configureWindow_setsWindowAsKeyAndVisible() {
        let window = UIWindowSpy()
        let sut = SceneDelegate()
        sut.window = window
        sut.configureWindow()
        XCTAssertEqual(window.makeKeyAndVisibleCallCount, 1, "Expected to make window key and visible")
    }

    func test_configureWindow_configuresRootViewController() throws {
        let sut = SceneDelegate()
        sut.window = UIWindow()

        sut.configureWindow()

        let root = sut.window?.rootViewController
        let rootNavigation = try XCTUnwrap(
            root as? UINavigationController,
            "Expected a navigation controller as root, got \(String(describing: root)) instead"
        )
        let topController = rootNavigation.topViewController
        XCTAssert(
            topController is FeedViewController,
            "Expected a feed controller as top view controller, got \(String(describing: topController)) instead"
        )
    }
}

private class UIWindowSpy: UIWindow {
    private(set) var makeKeyAndVisibleCallCount = 0

    override func makeKeyAndVisible() {
        makeKeyAndVisibleCallCount = 1
    }
}
