//
//  FeedImagePresenterTests.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 29/10/23.
//

import Feed
import XCTest

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

    func test_didFinishLoadingImageData_displaysRetryOnFailedImageTransformation() throws {
        let (sut, view) = makeSUT(imageTransformer: fail)
        let image = uniqueImage

        sut.didFinishLoadingImageData(with: Data(), for: image)

        let messages = view.messages
        XCTAssertEqual(messages.count, 1)

        let message = try XCTUnwrap(messages.first)
        XCTAssertEqual(message.description, image.description)
        XCTAssertEqual(message.location, image.location)
        XCTAssertFalse(message.isLoading)
        XCTAssert(message.shouldRetry)
        XCTAssertNil(message.image)
    }

    func test_didFinishLoadingImageData_displaysImageOnSuccessfulTransformation() throws {
        let image = uniqueImage
        let transformedData = AnyImage()
        let (sut, view) = makeSUT(imageTransformer: { _ in transformedData })

        sut.didFinishLoadingImageData(with: Data(), for: image)

        let messages = view.messages
        XCTAssertEqual(messages.count, 1)

        let message = try XCTUnwrap(messages.first)
        XCTAssertEqual(message.description, image.description)
        XCTAssertEqual(message.location, image.location)
        XCTAssertFalse(message.isLoading)
        XCTAssertFalse(message.shouldRetry)
        XCTAssertEqual(message.image, transformedData)
    }

    func test_didFinishLoadingImageDataWithError_displaysRetry() throws {
        let image = uniqueImage
        let (sut, view) = makeSUT()

        sut.didFinishLoadingImageData(with: anyNSError, for: image)

        let messages = view.messages
        XCTAssertEqual(messages.count, 1)

        let message = try XCTUnwrap(messages.first)
        XCTAssertEqual(view.messages.count, 1)
        XCTAssertEqual(message.description, image.description)
        XCTAssertEqual(message.location, image.location)
        XCTAssertFalse(message.isLoading)
        XCTAssert(message.shouldRetry)
        XCTAssertNil(message.image)
    }
}

private extension FeedImagePresenterTests {
    func makeSUT(
        imageTransformer: @escaping (Data) -> AnyImage? = { _ in nil },
        file: StaticString = #file,
        line: UInt = #line
    ) -> (sut: FeedImagePresenter<ViewSpy, AnyImage>, view: ViewSpy) {
        let view = ViewSpy()
        let sut = FeedImagePresenter(view: view, imageTransformer: imageTransformer)
        trackForMemoryLeaks(view, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, view)
    }

    var fail: (Data) -> AnyImage? {
        { _ in nil }
    }
}

private class ViewSpy: FeedImageView {
    private(set) var messages = [FeedImageViewModel<AnyImage>]()

    func display(_ model: FeedImageViewModel<AnyImage>) {
        messages.append(model)
    }
}

private struct AnyImage: Equatable {}
