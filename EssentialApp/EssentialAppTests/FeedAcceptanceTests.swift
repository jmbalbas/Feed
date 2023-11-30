//
//  FeedAcceptanceTests.swift
//  EssentialAppTests
//
//  Created by Juan Santiago Martín Balbás on 8/11/23.
//

@testable import EssentialApp
import Feed
import FeediOS
import XCTest

final class FeedAcceptanceTests: XCTestCase {
    func test_onLaunch_displaysRemoteFeedWhenCustomerHasConnectivity() {
        let feed = launch(httpClient: .online(response), store: .empty)

        XCTAssertEqual(feed.numberOfRenderedFeedImageViews, 2)
        XCTAssertEqual(feed.renderedFeedImageData(at: 0), makeImageData0())
        XCTAssertEqual(feed.renderedFeedImageData(at: 1), makeImageData1())
        XCTAssertTrue(feed.canLoadMoreFeed)

        feed.simulateLoadMoreFeedAction()

        XCTAssertEqual(feed.numberOfRenderedFeedImageViews, 3)
        XCTAssertEqual(feed.renderedFeedImageData(at: 0), makeImageData0())
        XCTAssertEqual(feed.renderedFeedImageData(at: 1), makeImageData1())
        XCTAssertEqual(feed.renderedFeedImageData(at: 2), makeImageData2())
        XCTAssertTrue(feed.canLoadMoreFeed)

        feed.simulateLoadMoreFeedAction()

        XCTAssertEqual(feed.numberOfRenderedFeedImageViews, 3)
        XCTAssertEqual(feed.renderedFeedImageData(at: 0), makeImageData0())
        XCTAssertEqual(feed.renderedFeedImageData(at: 1), makeImageData1())
        XCTAssertEqual(feed.renderedFeedImageData(at: 2), makeImageData2())
        XCTAssertFalse(feed.canLoadMoreFeed)
    }

    func test_onLaunch_displaysCachedRemoteFeedWhenCustomerHasNoConnectivity() {
        let sharedStore = InMemoryFeedStore.empty
        let onlineFeed = launch(httpClient: .online(response), store: sharedStore)
        onlineFeed.simulateFeedImageViewVisible(at: 0)
        onlineFeed.simulateFeedImageViewVisible(at: 1)

        onlineFeed.simulateLoadMoreFeedAction()
        onlineFeed.simulateFeedImageViewVisible(at: 2)

        let offlineFeed = launch(httpClient: .offline, store: sharedStore)

        XCTAssertEqual(offlineFeed.numberOfRenderedFeedImageViews, 3)
        XCTAssertEqual(offlineFeed.renderedFeedImageData(at: 0), makeImageData0())
        XCTAssertEqual(offlineFeed.renderedFeedImageData(at: 1), makeImageData1())
        XCTAssertEqual(offlineFeed.renderedFeedImageData(at: 2), makeImageData2())
    }

    func test_onLaunch_displaysEmptyFeedWhenCustomerHasNoConnectivityAndNoCache() {
        let feed = launch(httpClient: .offline, store: .empty)

        XCTAssertEqual(feed.numberOfRenderedFeedImageViews, 0)
    }

    func test_onEnteringBackground_deletesExpiredFeedCache() {
        let store = InMemoryFeedStore.withExpiredFeedCache

        enterBackground(with: store)

        XCTAssertNil(store.feedCache, "Expected to delete expired cache")
    }

    func test_onEnteringBackground_keepsNonExpiredFeedCache() {
        let store = InMemoryFeedStore.withNonExpiredFeedCache

        enterBackground(with: store)

        XCTAssertNotNil(store.feedCache, "Expected to keep non-expired cache")
    }

    func test_onFeedImageSelection_displaysComments() {
        let comments = showCommentsForFirstImage()

        XCTAssertEqual(comments.numberOfRenderedComments, 1)
        XCTAssertEqual(comments.commentMessage(at: 0), makeCommentMessage())
    }
}

private extension FeedAcceptanceTests {
    func launch(
        httpClient: HTTPClientStub = .offline,
        store: InMemoryFeedStore = .empty
    ) -> ListViewController {
        let sut = SceneDelegate(httpClient: httpClient, store: store)
        sut.window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 1))
        sut.configureWindow()

        let nav = sut.window?.rootViewController as? UINavigationController
        let vc = nav?.topViewController as! ListViewController
        vc.simulateAppearance()
        return vc
    }

    func enterBackground(with store: InMemoryFeedStore) {
        let sut = SceneDelegate(httpClient: HTTPClientStub.offline, store: store)
        sut.sceneWillResignActive(UIApplication.shared.connectedScenes.first!)
    }

    func showCommentsForFirstImage() -> ListViewController {
        let feed = launch(httpClient: .online(response), store: .empty)

        feed.simulateTapOnFeedImage(at: 0)
        RunLoop.current.run(until: Date())

        let nav = feed.navigationController
        let vc = nav?.topViewController as! ListViewController
        vc.simulateAppearance()
        return vc
    }

    func response(for url: URL) -> (Data, HTTPURLResponse) {
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (makeData(for: url), response)
    }

    func makeData(for url: URL) -> Data {
        switch url.path {
        case "/image-0": 
            makeImageData0()
        case "/image-1": 
            makeImageData1()
        case "/image-2":
            makeImageData2()
        case "/essential-feed/v1/feed" where url.query?.contains("after_id") == false:
            makeFirstFeedPageData()
        case "/essential-feed/v1/feed" where url.query?.contains("after_id=A28F5FE3-27A7-44E9-8DF5-53742D0E4A5A") == true:
            makeSecondFeedPageData()
        case "/essential-feed/v1/feed" where url.query?.contains("after_id=166FCDD7-C9F4-420A-B2D6-CE2EAFA3D82F") == true:
            makeLastEmptyFeedPageData()
        case "/essential-feed/v1/image/2AB2AE66-A4B7-4A16-B374-51BBAC8DB086/comments":
            makeCommentsData()
        default:
            Data()
        }
    }

    func makeImageData0() -> Data {
        UIImage.make(withColor: .red).pngData()!
    }

    func makeImageData1() -> Data {
        UIImage.make(withColor: .green).pngData()!
    }

    func makeImageData2() -> Data { 
        UIImage.make(withColor: .blue).pngData()!
    }

    func makeFirstFeedPageData() -> Data {
        try! JSONSerialization.data(
            withJSONObject: [
                "items": [
                    ["id": "2AB2AE66-A4B7-4A16-B374-51BBAC8DB086", "image": "http://feed.com/image-0"],
                    ["id": "A28F5FE3-27A7-44E9-8DF5-53742D0E4A5A", "image": "http://feed.com/image-1"]
                ]]
        )
    }

    func makeSecondFeedPageData() -> Data {
        try! JSONSerialization.data(
            withJSONObject: [
                "items": [
                    ["id": "166FCDD7-C9F4-420A-B2D6-CE2EAFA3D82F", "image": "http://feed.com/image-2"],
                ]]
        )
    }

    func makeLastEmptyFeedPageData() -> Data {
        try! JSONSerialization.data(withJSONObject: ["items": []])
    }

    func makeCommentsData() -> Data {
        try! JSONSerialization.data(withJSONObject: [
            "items": [
                [
                    "id": UUID().uuidString,
                    "message": makeCommentMessage(),
                    "created_at": "2020-05-20T11:24:59+0000",
                    "author": [
                        "username": "A11 username"
                    ]
                ],
            ]])
    }

    func makeCommentMessage() -> String {
        "A message"
    }
}
