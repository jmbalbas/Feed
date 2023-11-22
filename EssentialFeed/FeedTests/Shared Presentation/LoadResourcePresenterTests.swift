//
//  LoadResourcePresenterTests.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 22/11/23.
//

import Feed
import XCTest

final class LoadResourcePresenterTests: XCTestCase {
    func test_init_doesNotSendMessagesToView() {
        let (_, view) = makeSUT()

        XCTAssert(view.messages.isEmpty, "Expected no view messages")
    }

    func test_didStartLoadingFeed_displaysNoErrorMessageAndStartsLoading() {
        let (sut, view) = makeSUT()

        sut.didStartLoadingFeed()

        XCTAssertEqual(view.messages, [
            .display(errorMessage: .none),
            .display(isLoading: true)
        ])
    }

    func test_didFinishLoadingFeed_displaysFeedAndStopsLoading() {
        let (sut, view) = makeSUT()
        let feed = uniqueImageFeed.models

        sut.didFinishLoadingFeed(with: feed)

        XCTAssertEqual(view.messages, [
            .display(feed: feed),
            .display(isLoading: false)
        ])
    }

    func test_didFinishLoadingFeedWithError_displaysLocalizedErrorAndStopsLoading() {
        let (sut, view) = makeSUT()

        sut.didFinishLoadingFeed(with: anyNSError)

        XCTAssertEqual(view.messages, [
            .display(errorMessage: localized("FEED_VIEW_CONNECTION_ERROR")),
            .display(isLoading: false)
        ])
    }
}

private extension LoadResourcePresenterTests {
    func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: LoadResourcePresenter, view: ViewSpy) {
        let view = ViewSpy()
        let sut = LoadResourcePresenter(feedView: view, loadingView: view, errorView: view)
        trackForMemoryLeaks(view, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, view)
    }

    func localized(_ key: String, file: StaticString = #file, line: UInt = #line) -> String {
        let table = "Feed"
        let bundle = Bundle(for: LoadResourcePresenter.self)
        let value = bundle.localizedString(forKey: key, value: nil, table: table)
        if value == key {
            XCTFail("Missing localized string for key: \(key) in table: \(table)", file: file, line: line)
        }
        return value
    }
}

private class ViewSpy: FeedView, FeedLoadingView, FeedErrorView {
    enum Message: Hashable {
        case display(errorMessage: String?)
        case display(isLoading: Bool)
        case display(feed: [FeedImage])
    }

    private(set) var messages = Set<Message>()

    func display(_ viewModel: FeedLoadingViewModel) {
        messages.insert(.display(isLoading: viewModel.isLoading))
    }

    func display(_ viewModel: FeedErrorViewModel) {
        messages.insert(.display(errorMessage: viewModel.message))
    }

    func display(_ viewModel: FeedViewModel) {
        messages.insert(.display(feed: viewModel.feed))
    }
}
