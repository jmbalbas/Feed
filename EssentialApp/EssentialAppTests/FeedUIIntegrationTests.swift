//
//  FeedUIIntegrationTests.swift
//  FeediOSTests
//
//  Created by Juan Santiago Martín Balbás on 6/10/23.
//

import EssentialApp
import Feed
import FeediOS
import Foundation
import XCTest

@MainActor
final class FeedUIIntegrationTests: XCTestCase {
    func test_feedView_hasTitle() {
        let (sut, _) = makeSUT()
        sut.simulateAppearance()

        XCTAssertEqual(sut.title, feedTitle)
    }

    func test_loadFeedActions_requestFeedFromLoader() {
        let (sut, loader) = makeSUT()

        XCTAssertEqual(loader.loadFeedCallCount, 0, "Expected no loading requests before view is loaded")

        sut.simulateAppearance()
        XCTAssertEqual(loader.loadFeedCallCount, 1, "Expected a loading request once view is loaded")

        sut.simulateUserInitiatedFeedReload()
        XCTAssertEqual(loader.loadFeedCallCount, 2, "Expected another loading request once user initiates a load")

        sut.simulateUserInitiatedFeedReload()
        XCTAssertEqual(loader.loadFeedCallCount, 3, "Expected a third loading request once user initiates another load")
    }

    func test_loadingFeedIndicator_isVisibibleWhileLoadingFeed() {
        let (sut, loader) = makeSUT()

        sut.simulateAppearance()
        XCTAssert(sut.isShowingLoadingIndicator, "Expected loading indicator once view is loaded")

        loader.completeFeedLoading(at: 0)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once loading completes successfully")

        sut.simulateUserInitiatedFeedReload()
        XCTAssert(sut.isShowingLoadingIndicator, "Expected loading indicator once user initiates a reload")

        loader.completeFeedLoadingWithError(at: 1)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once user initiated loading completes with error")
    }

    func test_loadFeedCompletion_rendersSuccessfullyLoadedFeed() throws {
        let image0 = makeImage(description: "A description", location: "A location")
        let image1 = makeImage(description: nil, location: "Another location")
        let image2 = makeImage(description: "Another description", location: nil)
        let image3 = makeImage(description: nil, location: nil)

        let (sut, loader) = makeSUT()

        sut.simulateAppearance()
        try assertThat(sut, isRendering: [])

        loader.completeFeedLoading(with: [image0], at: 0)
        try assertThat(sut, isRendering: [image0])

        sut.simulateUserInitiatedFeedReload()
        loader.completeFeedLoading(with: [image0, image1, image2, image3], at: 1)
        try assertThat(sut, isRendering: [image0, image1, image2, image3])
    }

    func test_loadFeedCompletion_rendersSuccessfullyLoadedEmptyFeedAfterNonEmptyFeed() throws {
        let image0 = makeImage()
        let image1 = makeImage()

        let (sut, loader) = makeSUT()

        sut.simulateAppearance()

        loader.completeFeedLoading(with: [image0, image1], at: 0)
        try assertThat(sut, isRendering: [image0, image1])

        sut.simulateUserInitiatedFeedReload()
        loader.completeFeedLoading(with: [], at: 1)
        try assertThat(sut, isRendering: [])
    }

    func test_loadFeedCompletion_doesNotAlterCurrentRenderingStateOnError() throws {
        let image0 = makeImage()
        let (sut, loader) = makeSUT()

        sut.simulateAppearance()
        loader.completeFeedLoading(with: [image0], at: 0)
        try assertThat(sut, isRendering: [image0])

        sut.simulateUserInitiatedFeedReload()
        loader.completeFeedLoadingWithError(at: 1)
        try assertThat(sut, isRendering: [image0])
    }

    func test_loadFeedCompletion_rendersErrorMessageOnErrorUntilNextReload() {
        let (sut, loader) = makeSUT()

        sut.simulateAppearance()

        XCTAssertEqual(sut.errorMessage, nil)
        
        loader.completeFeedLoadingWithError(at: 0)
        XCTAssertEqual(sut.errorMessage, loadError)

        sut.simulateUserInitiatedFeedReload()
        XCTAssertEqual(sut.errorMessage, nil)
    }

    func test_tapOnErrorView_hidesErrorMessage() {
        let (sut, loader) = makeSUT()

        sut.simulateAppearance()
        
        XCTAssertEqual(sut.errorMessage, nil)

        loader.completeFeedLoadingWithError(at: 0)
        XCTAssertEqual(sut.errorMessage, loadError)

        sut.simulateErrorViewTap()
        XCTAssertEqual(sut.errorMessage, nil)
    }

    func test_feedImageView_loadsImageURLWhenVisible() {
        let image0 = makeImage(url: URL(string: "https://url-0.com")!)
        let image1 = makeImage(url: URL(string: "https://url-1.com")!)
        let (sut, loader) = makeSUT()

        sut.simulateAppearance()
        loader.completeFeedLoading(with: [image0, image1])

        XCTAssertEqual(loader.loadedImageURLs, [], "Expected no image URL requests until views become visible")

        sut.simulateFeedImageViewVisible(at: 0)
        XCTAssertEqual(loader.loadedImageURLs, [image0.url], "Expected first image URL request once first view becomes visible")


        sut.simulateFeedImageViewVisible(at: 1)
        XCTAssertEqual(loader.loadedImageURLs, [image0.url, image1.url], "Expected second image URL request once second view also becomes visible")
    }

    func test_feedImageView_cancelsImageLoadingWhenNotVisibleAnymore() {
        let image0 = makeImage(url: URL(string: "https://url-0.com")!)
        let image1 = makeImage(url: URL(string: "https://url-1.com")!)
        let (sut, loader) = makeSUT()

        sut.simulateAppearance()
        loader.completeFeedLoading(with: [image0, image1])
        XCTAssertEqual(loader.cancelledImageURLs, [], "Expected no cancelled image URL request until image is not visible")

        sut.simulateFeedImageViewNotVisible(at: 0)
        XCTAssertEqual(loader.cancelledImageURLs, [image0.url], "Expected one cancelled image URL request after first image is not visible")


        sut.simulateFeedImageViewNotVisible(at: 1)
        XCTAssertEqual(loader.loadedImageURLs, [image0.url, image1.url], "Expected two cancelled image URL requests once second image is also not visible anymore")
    }

    func test_feedImageView_reloadsImageURLWhenBecomingVisibleAgain() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-1.com")!)
        let (sut, loader) = makeSUT()

        sut.simulateAppearance()
        loader.completeFeedLoading(with: [image0, image1])

        sut.simulateFeedImageBecomingVisibleAgain(at: 0)

        XCTAssertEqual(loader.loadedImageURLs, [image0.url, image0.url], "Expected two image URL request after first view becomes visible again")

        sut.simulateFeedImageBecomingVisibleAgain(at: 1)

        XCTAssertEqual(loader.loadedImageURLs, [image0.url, image0.url, image1.url, image1.url], "Expected two new image URL request after second view becomes visible again")
    }

    func test_feedImageViewLoadingIndicator_isVisibleWhileLoadingImage() throws {
        let (sut, loader) = makeSUT()

        sut.simulateAppearance()
        loader.completeFeedLoading(with: [makeImage(), makeImage()])

        let view0 = try XCTUnwrap(sut.simulateFeedImageViewVisible(at: 0))
        let view1 = try XCTUnwrap(sut.simulateFeedImageViewVisible(at: 1))
        XCTAssert(view0.isShowingImageLoadingIncator, "Expected loading indicator for first view while loading first image")
        XCTAssert(view1.isShowingImageLoadingIncator, "Expected loading indicator for second view while loading second image")

        loader.completeImageLoading(at: 0)
        XCTAssertFalse(view0.isShowingImageLoadingIncator, "Expected no loading indicator for first view once first image loading completes successfully")
        XCTAssert(view1.isShowingImageLoadingIncator, "Expected no loading indicator state change for second view once first image loading completes successfully")

        loader.completeImageLoadingWithError(at: 1)
        XCTAssertFalse(view0.isShowingImageLoadingIncator, "Expected no loading indicator state change for first view once second image loading completes with error")
        XCTAssertFalse(view1.isShowingImageLoadingIncator, "Expected no loading indicator for second view once second image loading completes with error")
    }

    func test_feedImageView_rendersImageLoadedFromURL() throws {
        let (sut, loader) = makeSUT()

        sut.simulateAppearance()
        loader.completeFeedLoading(with: [makeImage(), makeImage()])

        let view0 = try XCTUnwrap(sut.simulateFeedImageViewVisible(at: 0))
        let view1 = try XCTUnwrap(sut.simulateFeedImageViewVisible(at: 1))
        XCTAssertNil(view0.renderedImage, "Expected no image for first view while loading first image")
        XCTAssertNil(view1.renderedImage, "Expected no image for second view while loading second image")

        let imageData0 = try XCTUnwrap(UIImage.make(withColor: .red).pngData())
        loader.completeImageLoading(with: imageData0, at: 0)
        XCTAssertEqual(view0.renderedImage, imageData0, "Expected image for first view once first image loading completes successfully")
        XCTAssertNil(view1.renderedImage, "Expected no image state change for second view once first image loading completes successfully")

        let imageData1 = try XCTUnwrap(UIImage.make(withColor: .blue).pngData())
        loader.completeImageLoading(with: imageData1, at: 1)
        XCTAssertEqual(view0.renderedImage, imageData0, "Expected no image state change for first view once second image loading completes successfully")
        XCTAssertEqual(view1.renderedImage, imageData1, "Expected image for second view once second image loading completes successfully")
    }

    func test_feedImageViewRetryButton_isVisibleOnImageURLLoadError() throws {
        let (sut, loader) = makeSUT()

        sut.simulateAppearance()
        loader.completeFeedLoading(with: [makeImage(), makeImage()])

        let view0 = try XCTUnwrap(sut.simulateFeedImageViewVisible(at: 0))
        let view1 = try XCTUnwrap(sut.simulateFeedImageViewVisible(at: 1))
        XCTAssertFalse(view0.isShowingRetryAction, "Expected no retry action for first view while loading first image")
        XCTAssertFalse(view1.isShowingRetryAction, "Expected no retry action for second view while loading second image")

        let imageData = try XCTUnwrap(UIImage.make(withColor: .red).pngData())
        loader.completeImageLoading(with: imageData, at: 0)
        XCTAssertFalse(view0.isShowingRetryAction, "Expected no retry action for first view once first image loading completes successfully")
        XCTAssertFalse(view1.isShowingRetryAction, "Expected no retry action state change for second view once first image loading completes successfully")

        loader.completeImageLoadingWithError(at: 1)
        XCTAssertFalse(view0.isShowingRetryAction, "Expected no retry action state change for first view once second image loading completes with error")
        XCTAssert(view1.isShowingRetryAction, "Expected retry action for second view once second image loading completes with error")
    }

    func test_feedImageViewRetryButton_isVisibleOnInvalidImageData() throws {
        let (sut, loader) = makeSUT()

        sut.simulateAppearance()
        loader.completeFeedLoading(with: [makeImage()])

        let view = try XCTUnwrap(sut.simulateFeedImageViewVisible(at: 0))
        XCTAssertFalse(view.isShowingRetryAction, "Expected no retry action while loading image")

        let invalidImageData = Data("Invalid image data".utf8)
        loader.completeImageLoading(with: invalidImageData, at: 0)
        XCTAssert(view.isShowingRetryAction, "Expected retry action once image loading completes with invalid image data")
    }

    func test_feedImageViewRetryAction_retriesImageLoad() throws {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-1.com")!)
        let (sut, loader) = makeSUT()

        sut.simulateAppearance()
        loader.completeFeedLoading(with: [image0, image1])

        let view0 = try XCTUnwrap(sut.simulateFeedImageViewVisible(at: 0))
        let view1 = try XCTUnwrap(sut.simulateFeedImageViewVisible(at: 1))
        XCTAssertEqual(loader.loadedImageURLs, [image0.url, image1.url], "Expected two image URL request for the two visible views")

        loader.completeImageLoadingWithError(at: 0)
        loader.completeImageLoadingWithError(at: 1)
        XCTAssertEqual(loader.loadedImageURLs, [image0.url, image1.url], "Expected only two image URL requests before retry action")

        view0.simulateRetryAction()
        XCTAssertEqual(loader.loadedImageURLs, [image0.url, image1.url, image0.url], "Expected third imageURL request after first view retry action")

        view1.simulateRetryAction()
        XCTAssertEqual(loader.loadedImageURLs, [image0.url, image1.url, image0.url, image1.url], "Expected fourth imageURL request after second view retry action")
    }

    func test_feedImageView_preloadsImageURLWhenNearVisible() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-1.com")!)
        let (sut, loader) = makeSUT()

        sut.simulateAppearance()
        loader.completeFeedLoading(with: [image0, image1])
        XCTAssertEqual(loader.loadedImageURLs, [], "Expected no image URL requests until image is near visible")

        sut.simulateFeedImageViewNearVisible(at: 0)
        XCTAssertEqual(loader.loadedImageURLs, [image0.url], "Expected first image URL request once first image is near visible")

        sut.simulateFeedImageViewNearVisible(at: 1)
        XCTAssertEqual(loader.loadedImageURLs, [image0.url, image1.url], "Expected second image URL request once second image is near visible")
    }

    func test_feedImageView_cancelsImageURLPreloadingWhenNotNearVisibleAnymore() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-1.com")!)
        let (sut, loader) = makeSUT()

        sut.simulateAppearance()
        loader.completeFeedLoading(with: [image0, image1])
        XCTAssertEqual(loader.cancelledImageURLs, [], "Expected no cancelled image URL requests until image is not near visible")

        sut.simulateFeedImageViewNotNearVisible(at: 0)
        XCTAssertEqual(loader.cancelledImageURLs, [image0.url], "Expected first cancelled image URL request once first image is not near visible anymore")

        sut.simulateFeedImageViewNotNearVisible(at: 1)
        XCTAssertEqual(loader.cancelledImageURLs, [image0.url, image1.url], "Expected second cancelled image URL request once second image is not near visible anymore")
    }

    func test_feedImageView_configuresViewCorrectlyWhenCellBecomingVisibleAgain() throws {
        let (sut, loader) = makeSUT()

        sut.simulateAppearance()
        loader.completeFeedLoading(with: [makeImage()])

        let view0 = try XCTUnwrap(sut.simulateFeedImageBecomingVisibleAgain(at: 0))

        XCTAssertNil(view0.renderedImage, "Expected no rendered image when view becomes visible again")
        XCTAssertFalse(view0.isShowingRetryAction, "Expected no retry action when view becomes visible again")
        XCTAssert(view0.isShowingImageLoadingIncator, "Expected loading indicator when view becomes visible again")

        let imageData = try XCTUnwrap(UIImage.make(withColor: .red).pngData())
        loader.completeImageLoading(with: imageData, at: 1)

        XCTAssertEqual(view0.renderedImage, imageData, "Expected rendered image when image loads successfully after view becomes visible again")
        XCTAssertFalse(view0.isShowingRetryAction, "Expected no retry when image loads successfully after view becomes visible again")
        XCTAssertFalse(view0.isShowingImageLoadingIncator, "Expected no loading indicator when image loads successfully after view becomes visible again")
    }
    
    func test_feedImageView_doesNotShowDataFromPreviousRequestWhenCellIsReused() throws {
        let (sut, loader) = makeSUT()

        sut.simulateAppearance()
        loader.completeFeedLoading(with: [makeImage(), makeImage()])

        let view0 = try XCTUnwrap(sut.simulateFeedImageViewVisible(at: 0))
        view0.prepareForReuse()

        let imageData0 = try XCTUnwrap(UIImage.make(withColor: .red).pngData())
        loader.completeImageLoading(with: imageData0, at: 0)

        XCTAssertEqual(view0.renderedImage, .none, "Expected no image state change for reused view once image loading completes successfully")
    }

    func test_feedImageView_showsDataForNewViewRequestAfterPreviousViewIsReused() throws {
        let (sut, loader) = makeSUT()

        sut.simulateAppearance()
        loader.completeFeedLoading(with: [makeImage(), makeImage()])

        let previousView = try XCTUnwrap(sut.simulateFeedImageViewNotVisible(at: 0))

        let newView = try XCTUnwrap(sut.simulateFeedImageViewVisible(at: 0))
        previousView.prepareForReuse()

        let imageData = try XCTUnwrap(UIImage.make(withColor: .red).pngData())
        loader.completeImageLoading(with: imageData, at: 1)

        XCTAssertEqual(newView.renderedImage, imageData)
    }

    func test_feedImageView_doesNotRenderLoadedImageWhenNotVisibleAnymore() {
        let (sut, loader) = makeSUT()
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [makeImage()])

        let view = sut.simulateFeedImageViewNotVisible(at: 0)
        loader.completeImageLoading(with: anyImageData)

        XCTAssertNil(view.renderedImage, "Expected no rendered image when an image load finishes after the view is not visible anymore")
    }

    func test_loadFeedCompletion_dispatchesFromBackgroundToMainThread() async {
        let (sut, loader) = makeSUT()
        sut.simulateAppearance()

        await Task.detached {
            loader.completeFeedLoading()
        }.value
    }

    func test_loadImageDataCompletion_dispatchesFromBackgroundToMainThread() async {
        let (sut, loader) = makeSUT()
        sut.simulateAppearance()

        loader.completeFeedLoading(with: [makeImage()])
        _ = sut.simulateFeedImageViewVisible(at: 0)

        await Task.detached {
            await loader.completeImageLoading(with: self.anyImageData)
        }.value
    }
}

private extension FeedUIIntegrationTests {
    func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: ListViewController, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = FeedUIComposer.feedComposedWith(feedLoader: loader.loadPublisher, imageLoader: loader.loadImageDataPublisher)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader)
    }

    func makeImage(
        description: String? = nil,
        location: String? = nil,
        url: URL = URL(string: "https://any-url.com")!
    ) -> FeedImage {
        FeedImage(id: UUID(), description: description, location: location, url: url)
    }

    var anyImageData: Data {
        UIImage.make(withColor: .red).pngData()!
    }
}
