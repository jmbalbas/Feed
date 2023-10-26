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
        let (_, view) = makeSUT()

        XCTAssert(view.messages.isEmpty, "Expected no view messages")
    }
}

private extension FeedPresenterTests {
    func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: FeedPresenter, view: ViewSpy) {
        let view = ViewSpy()
        let sut = FeedPresenter(view: view)
        trackForMemoryLeaks(view, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, view)
    }
}

private class ViewSpy {
    var messages: [Any] = []
}
