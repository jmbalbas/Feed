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
    func test_sceneWillConnectToSession_configuresRootViewController() throws {
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
