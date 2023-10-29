//
//  FeedImagePresenterTests.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 29/10/23.
//

import Feed
import XCTest

struct FeedImageViewModel {
    let description: String?
    let location: String?
    let image: Any?
    let isLoading: Bool
    let shouldRetry: Bool

    var hasLocation: Bool {
        location != nil
    }
}

protocol FeedImageView {
    func display(_ model: FeedImageViewModel)
}

class FeedImagePresenter {
    private let view: FeedImageView

    init(view: FeedImageView) {
        self.view = view
    }

    func didStartLoadingImageData(for model: FeedImage) {
        view.display(FeedImageViewModel(
            description: model.description,
            location: model.location,
            image: nil,
            isLoading: true,
            shouldRetry: false
        ))
    }
}

final class FeedImagePresenterTests: XCTestCase {
    func test_init_doesNotSendMessagesToView() {
        let (_, view) = makeSUT()

        XCTAssert(view.messages.isEmpty, "Expected no view messages")
    }

    func test_didStartLoadingImageData_displaysLoadingImage() throws {
        let (sut, view) = makeSUT()
        let image = uniqueImage

        sut.didStartLoadingImageData(for: image)

        let messages = view.messages
        XCTAssertEqual(messages.count, 1)

        let message = try XCTUnwrap(messages.first)
        XCTAssertEqual(message.description, image.description)
        XCTAssertEqual(message.location, image.location)
        XCTAssert(message.isLoading)
        XCTAssertFalse(message.shouldRetry)
        XCTAssertNil(message.image)
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

private class ViewSpy: FeedImageView {
    private(set) var messages = [FeedImageViewModel]()

    func display(_ model: FeedImageViewModel) {
        messages.append(model)
    }
}
