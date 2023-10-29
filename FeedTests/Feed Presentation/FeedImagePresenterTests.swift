//
//  FeedImagePresenterTests.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 29/10/23.
//

import XCTest

class FeedImagePresenter {
    init(view: Any) {

    }
}

final class FeedImagePresenterTests: XCTestCase {

    func test_init_doesNotSendMessagesToView() {
        let (_, view) = makeSUT()

        XCTAssert(view.messages.isEmpty, "Expected no view messages")
    }
}

private extension FeedImagePresenterTests {
    func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: FeedImagePresenter, view: ViewSpy) {
        let view = ViewSpy()
        let sut = FeedImagePresenter(view: view)
        trackForMemoryLeaks(view, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, view)
    }
}

private class ViewSpy {
    let messages = [Any]()
}
