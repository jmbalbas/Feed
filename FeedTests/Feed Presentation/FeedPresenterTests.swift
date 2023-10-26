//
//  FeedPresenterTests.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 26/10/23.
//

import XCTest

final class FeedPresenter {
    init(view: Any) {}
}

final class FeedPresenterTests: XCTestCase {
    func test_init_doesNotSendMessagesToView() {
        let view = ViewSpy()

        _ = FeedPresenter(view: view)

        XCTAssert(view.messages.isEmpty, "Expected no view messages")
    }
}

private class ViewSpy {
    var messages: [Any] = []
}
