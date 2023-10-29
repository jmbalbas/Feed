//
//  FeedImagePresenterTests.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 29/10/23.
//

import Feed
import XCTest

struct FeedImageViewModel<Image> {
    let description: String?
    let location: String?
    let image: Image?
    let isLoading: Bool
    let shouldRetry: Bool

    var hasLocation: Bool {
        location != nil
    }
}

protocol FeedImageView {
    associatedtype Image

    func display(_ model: FeedImageViewModel<Image>)
}

final class FeedImagePresenter<View: FeedImageView, Image> where View.Image == Image {
    private let view: View
    private let imageTransformer: (Data) -> Image?

    init(view: View, imageTransformer: @escaping (Data) -> Image?) {
        self.view = view
        self.imageTransformer = imageTransformer
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

    func didFinishLoadingImageData(with data: Data, for model: FeedImage) {
        let image = imageTransformer(data)
        view.display(FeedImageViewModel(
            description: model.description,
            location: model.location,
            image: image,
            isLoading: false,
            shouldRetry: image == nil
        ))
    }

    func didFinishLoadingImageData(with error: Error, for model: FeedImage) {
        view.display(FeedImageViewModel(
            description: model.description,
            location: model.location,
            image: nil,
            isLoading: false,
            shouldRetry: true
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

    func test_didFinishLoadingImageData_displaysRetryOnFailedImageTransformation() throws {
        let (sut, view) = makeSUT(imageTransformer: fail)
        let image = uniqueImage
        let data = Data()

        sut.didFinishLoadingImageData(with: data, for: image)

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
        let data = Data()
        let transformedData = AnyImage()
        let (sut, view) = makeSUT(imageTransformer: { _ in transformedData })

        sut.didFinishLoadingImageData(with: data, for: image)

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
