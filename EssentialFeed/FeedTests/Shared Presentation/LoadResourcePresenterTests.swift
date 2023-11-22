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

    func test_didStartLoading_displaysNoErrorMessageAndStartsLoading() {
        let (sut, view) = makeSUT()

        sut.didStartLoading()

        XCTAssertEqual(view.messages, [
            .display(errorMessage: .none),
            .display(isLoading: true)
        ])
    }

    func test_didFinishLoadingResource_displaysResourceAndStopsLoading() {
        let (sut, view) = makeSUT(mapper: { resource in
            resource + " view model"
        })

        sut.didFinishLoading(with: "Resource")

        XCTAssertEqual(view.messages, [
            .display(resourceViewModel: "Resource view model"),
            .display(isLoading: false)
        ])
    }

    func test_didFinishLoadingWithError_displaysLocalizedErrorAndStopsLoading() {
        let (sut, view) = makeSUT()

        sut.didFinishLoading(with: anyNSError)

        XCTAssertEqual(view.messages, [
            .display(errorMessage: localized("GENERIC_CONNECTION_ERROR")),
            .display(isLoading: false)
        ])
    }
}

private extension LoadResourcePresenterTests {
    typealias SUT = LoadResourcePresenter<String, ViewSpy>
    
    func makeSUT(
        mapper: @escaping SUT.Mapper = { _ in "any" },
        file: StaticString = #file,
        line: UInt = #line
    ) -> (sut: SUT, view: ViewSpy) {
        let view = ViewSpy()
        let sut = SUT(resourceView: view, loadingView: view, errorView: view, mapper: mapper)
        trackForMemoryLeaks(view, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, view)
    }

    func localized(_ key: String, file: StaticString = #file, line: UInt = #line) -> String {
        let table = "Shared"
        let bundle = Bundle(for: SUT.self)
        let value = bundle.localizedString(forKey: key, value: nil, table: table)
        if value == key {
            XCTFail("Missing localized string for key: \(key) in table: \(table)", file: file, line: line)
        }
        return value
    }
}

private class ViewSpy: ResourceView, ResourceLoadingView, ResourceErrorView {
    typealias ResourceViewModel = String

    enum Message: Hashable {
        case display(errorMessage: String?)
        case display(isLoading: Bool)
        case display(resourceViewModel: String)
    }

    private(set) var messages = Set<Message>()

    func display(_ viewModel: ResourceLoadingViewModel) {
        messages.insert(.display(isLoading: viewModel.isLoading))
    }

    func display(_ viewModel: ResourceErrorViewModel) {
        messages.insert(.display(errorMessage: viewModel.message))
    }

    func display(_ viewModel: String) {
        messages.insert(.display(resourceViewModel: viewModel))
    }
}
