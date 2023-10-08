//
//  FeedViewControllerTests.swift
//  FeediOSTests
//
//  Created by Juan Santiago Martín Balbás on 6/10/23.
//

import Feed
import FeediOS
import Foundation
import XCTest

@MainActor
final class FeedViewControllerTests: XCTestCase {
    func test_loadFeedActions_requestFeedFromLoader() {
        let (sut, loader) = makeSUT()

        XCTAssertEqual(loader.loadFeedCallCount, 0, "Expected no loading requests before view is loaded")

        sut.loadViewIfNeeded()
        XCTAssertEqual(loader.loadFeedCallCount, 1, "Expected a loading request once view is loaded")

        sut.simulateUserInitiatedFeedReload()
        XCTAssertEqual(loader.loadFeedCallCount, 2, "Expected another loading request once user initiates a load")

        sut.simulateUserInitiatedFeedReload()
        XCTAssertEqual(loader.loadFeedCallCount, 3, "Expected a third loading request once user initiates another load")
    }

    func test_loadingFeedIndicator_isVisibibleWhileLoadingFeed() {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
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

        sut.loadViewIfNeeded()
        try assertThat(sut, isRendering: [])

        loader.completeFeedLoading(with: [image0], at: 0)
        try assertThat(sut, isRendering: [image0])

        sut.simulateUserInitiatedFeedReload()
        loader.completeFeedLoading(with: [image0, image1, image2, image3], at: 1)
        try assertThat(sut, isRendering: [image0, image1, image2, image3])
    }

    func test_loadFeedCompletion_doesNotAlterCurrentRenderingStateOnError() throws {
        let image0 = makeImage()
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        loader.completeFeedLoading(with: [image0], at: 0)
        try assertThat(sut, isRendering: [image0])

        sut.simulateUserInitiatedFeedReload()
        loader.completeFeedLoadingWithError(at: 1)
        try assertThat(sut, isRendering: [image0])
    }

    func test_feedImageView_loadsImageURLWhenVisible() {
        let image0 = makeImage(url: URL(string: "https://url-0.com")!)
        let image1 = makeImage(url: URL(string: "https://url-1.com")!)
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
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

        sut.loadViewIfNeeded()
        loader.completeFeedLoading(with: [image0, image1])
        XCTAssertEqual(loader.cancelledImageURLs, [], "Expected no cancelled image URL request until image is not visible")

        sut.simulateFeedImageViewNotVisible(at: 0)
        XCTAssertEqual(loader.cancelledImageURLs, [image0.url], "Expected one cancelled image URL request after first image is not visible")


        sut.simulateFeedImageViewNotVisible(at: 1)
        XCTAssertEqual(loader.loadedImageURLs, [image0.url, image1.url], "Expected two cancelled image URL requests once second image is also not visible anymore")
    }

    func test_feedImageViewLoadingIndicator_isVisibleWhileLoadingImage() throws {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
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

        sut.loadViewIfNeeded()
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

        sut.loadViewIfNeeded()
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

        sut.loadViewIfNeeded()
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

        sut.loadViewIfNeeded()
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

        sut.loadViewIfNeeded()
        loader.completeFeedLoading(with: [image0, image1])
        XCTAssertEqual(loader.loadedImageURLs, [], "Expected no image URL requests until image is near visible")

        sut.simulateFeedImageViewNearVisible(at: 0)
        XCTAssertEqual(loader.loadedImageURLs, [image0.url], "Expected first image URL request once first image is near visible")

        sut.simulateFeedImageViewNearVisible(at: 1)
        XCTAssertEqual(loader.loadedImageURLs, [image0.url, image1.url], "Expected second image URL request once second image is near visible")
    }

}

private extension FeedViewControllerTests {
    func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: FeedViewController, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = FeedViewController(feedLoader: loader, imageLoader: loader)
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

    func assertThat(
        _ sut: FeedViewController,
        isRendering feed: [FeedImage],
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        guard sut.numberOfRenderedFeedImageViews == feed.count else {
            return XCTFail("Expected \(feed.count) images, got \(sut.numberOfRenderedFeedImageViews) instead.", file: file, line: line)
        }

        try feed.enumerated().forEach {
            try assertThat(sut, hasViewConfiguredFor: $0.element, at: $0.offset, file: file, line: line)
        }
    }

    func assertThat(
        _ sut: FeedViewController,
        hasViewConfiguredFor image: FeedImage,
        at index: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let view = sut.feedImageView(at: index)

        let cell = try XCTUnwrap(
            view as? FeedImageCell,
            "Expected \(FeedImageCell.self) instance, got \(String(describing: view)) instead",
            file: file,
            line: line
        )

        let shouldLocationBeVisible = image.location != nil
        XCTAssertEqual(
            cell.isShowingLocation,
            shouldLocationBeVisible,
            "Expected `isShowingLocation` to be \(shouldLocationBeVisible) for image view at index \(index)",
            file: file,
            line: line
        )

        XCTAssertEqual(
            cell.locationText,
            image.location,
            "Expected location text to be \(String(describing: image.location)) for image view at index \(index)",
            file: file,
            line: line
        )

        XCTAssertEqual(
            cell.descriptionText,
            image.description,
            "Expected description text to be \(String(describing: image.description)) for image view at index \(index)",
            file: file,
            line: line
        )
    }
}

class LoaderSpy: FeedLoader, FeedImageDataLoader {
    // MARK: - FeedLoader
    private var feedRequests: [(Result<[FeedImage], Error>) -> Void] = []

    var loadFeedCallCount: Int {
        feedRequests.count
    }

    func load(completion: @escaping (Result<[FeedImage], Error>) -> Void) {
        feedRequests.append(completion)
    }

    func completeFeedLoading(with feed: [FeedImage] = [], at index: Int = 0) {
        feedRequests[index](.success(feed))
    }

    func completeFeedLoadingWithError(at index: Int) {
        let error = NSError(domain: "An error", code: 0)
        feedRequests[index](.failure(error))
    }

    // MARK: - ImageLoader
    private struct TaskSpy: FeedImageDataLoaderTask {
        let cancelCallback: () -> Void

        func cancel() {
            cancelCallback()
        }
    }

    private var imageRequests: [(url: URL, completion: (FeedImageDataLoader.Result) -> Void)] = []
    var loadedImageURLs: [URL] {
        imageRequests.map(\.url)
    }
    private(set) var cancelledImageURLs: [URL] = []

    func loadImageData(
        from url: URL,
        completion: @escaping (FeedImageDataLoader.Result) -> Void
    ) -> FeedImageDataLoaderTask {
        imageRequests.append((url, completion))
        return TaskSpy { [weak self] in
            self?.cancelledImageURLs.append(url)
        }
    }

    func completeImageLoading(with imageData: Data = Data(), at index: Int = 0) {
        imageRequests[index].completion(.success(imageData))
    }

    func completeImageLoadingWithError(at index: Int) {
        let error = NSError(domain: "An error", code: 0)
        imageRequests[index].completion(.failure(error))
    }
}

private extension UIRefreshControl {
    func simulatePullToRefresh() {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: .valueChanged)?.forEach { action in
                (target as NSObject).perform(Selector(action))
            }
        }
    }
}

private extension UIButton {
    func simulateTap() {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: .touchUpInside)?.forEach { action in
                (target as NSObject).perform(Selector(action))
            }
        }
    }
}

private extension FeedViewController {
    var isShowingLoadingIndicator: Bool {
        refreshControl?.isRefreshing == true
    }

    func simulateUserInitiatedFeedReload() {
        refreshControl?.simulatePullToRefresh()
    }

    var numberOfRenderedFeedImageViews: Int {
        tableView.numberOfRows(inSection: feedImagesSection)
    }

    var feedImagesSection: Int {
        0
    }

    func feedImageView(at row: Int) -> UITableViewCell? {
        tableView(tableView, cellForRowAt: IndexPath(row: row, section: feedImagesSection))
    }

    @discardableResult
    func simulateFeedImageViewVisible(at index: Int) -> FeedImageCell? {
        feedImageView(at: index) as? FeedImageCell
    }

    func simulateFeedImageViewNotVisible(at index: Int) {
        let view = simulateFeedImageViewVisible(at: index)!
        tableView(tableView, didEndDisplaying: view, forRowAt: IndexPath(row: index, section: feedImagesSection))
    }

    func simulateFeedImageViewNearVisible(at row: Int) {
        let indexPath = IndexPath(row: row, section: feedImagesSection)
        tableView.prefetchDataSource?.tableView(tableView, prefetchRowsAt: [indexPath])
    }
}

private extension FeedImageCell {
    var isShowingLocation: Bool {
        !locationContainer.isHidden
    }

    var locationText: String? {
        locationLabel.text
    }

    var descriptionText: String? {
        descriptionLabel.text
    }

    var isShowingImageLoadingIncator: Bool {
        feedImageContainer.isShimmering
    }

    var renderedImage: Data? {
        feedImageView.image?.pngData()
    }

    var isShowingRetryAction: Bool {
        !feedImageRetryButton.isHidden
    }

    func simulateRetryAction() {
        feedImageRetryButton.simulateTap()
    }
}

private extension UIImage {
    static func make(withColor color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        return UIGraphicsImageRenderer(size: rect.size, format: format).image { rendererContext in
            color.setFill()
            rendererContext.fill(rect)
        }
    }
}
