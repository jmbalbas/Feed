//
//  CommentsUIIntegrationTests.swift
//  EssentialAppTests
//
//  Created by Juan Santiago Martín Balbás on 26/11/23.
//

import Combine
import EssentialApp
import Feed
import FeediOS
import Foundation
import XCTest

final class CommentsUIIntegrationTests: FeedUIIntegrationTests {
    func test_commentsView_hasTitle() {
        let (sut, _) = makeSUT()

        sut.simulateAppearance()

        XCTAssertEqual(sut.title, commentsTitle)
    }

    func test_loadCommentsActions_requestCommentsFromLoader() {
        let (sut, loader) = makeSUT()
        XCTAssertEqual(loader.loadCommentsCallCount, 0, "Expected no loading requests before view is loaded")

        sut.simulateAppearance()
        XCTAssertEqual(loader.loadCommentsCallCount, 1, "Expected a loading request once view is loaded")

        sut.simulateUserInitiatedReload()
        XCTAssertEqual(loader.loadCommentsCallCount, 2, "Expected another loading request once user initiates a reload")

        sut.simulateUserInitiatedReload()
        XCTAssertEqual(loader.loadCommentsCallCount, 3, "Expected yet another loading request once user initiates another reload")
    }

    func test_loadingCommentsIndicator_isVisibleWhileLoadingComments() {
        let (sut, loader) = makeSUT()

        sut.simulateAppearance()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once view is loaded")

        loader.completeCommentsLoading(at: 0)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once loading completes successfully")

        sut.simulateUserInitiatedReload()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once user initiates a reload")

        loader.completeFeedLoadingWithError(at: 1)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once user initiated loading completes with error")
    }

    func test_loadCommentsCompletion_rendersSuccessfullyLoadedComments() {
        let comment0 = makeComment(message: "a message", username: "a username")
        let comment1 = makeComment(message: "another message", username: "another username")
        let (sut, loader) = makeSUT()

        sut.simulateAppearance()
        assertThat(sut, isRendering: [ImageComment]())

        loader.completeCommentsLoading(with: [comment0], at: 0)
        assertThat(sut, isRendering: [comment0])

        sut.simulateUserInitiatedReload()
        loader.completeCommentsLoading(with: [comment0, comment1], at: 1)
        assertThat(sut, isRendering: [comment0, comment1])
    }

    func test_loadCommentsCompletion_rendersSuccessfullyLoadedEmptyCommentsAfterNonEmptyComments() {
        let comment = makeComment()
        let (sut, loader) = makeSUT()

        sut.simulateAppearance()
        loader.completeCommentsLoading(with: [comment], at: 0)
        assertThat(sut, isRendering: [comment])

        sut.simulateUserInitiatedReload()
        loader.completeCommentsLoading(with: [], at: 1)
        assertThat(sut, isRendering: [ImageComment]())
    }

    func test_loadCommentsCompletion_doesNotAlterCurrentRenderingStateOnError() {
        let comment = makeComment()
        let (sut, loader) = makeSUT()

        sut.simulateAppearance()
        loader.completeCommentsLoading(with: [comment], at: 0)
        assertThat(sut, isRendering: [comment])

        sut.simulateUserInitiatedReload()
        loader.completeFeedLoadingWithError(at: 1)
        assertThat(sut, isRendering: [comment])
    }

    override func test_loadFeedCompletion_dispatchesFromBackgroundToMainThread() async {
        let (sut, loader) = makeSUT()
        sut.simulateAppearance()

        await Task.detached {
            loader.completeCommentsLoading()
        }.value
    }

    override func test_loadFeedCompletion_rendersErrorMessageOnErrorUntilNextReload() {
        let (sut, loader) = makeSUT()

        sut.simulateAppearance()
        XCTAssertEqual(sut.errorMessage, nil)

        loader.completeFeedLoadingWithError(at: 0)
        XCTAssertEqual(sut.errorMessage, loadError)

        sut.simulateUserInitiatedReload()
        XCTAssertEqual(sut.errorMessage, nil)
    }

    override func test_tapOnErrorView_hidesErrorMessage() {
        let (sut, loader) = makeSUT()

        sut.simulateAppearance()
        XCTAssertEqual(sut.errorMessage, nil)

        loader.completeFeedLoadingWithError(at: 0)
        XCTAssertEqual(sut.errorMessage, loadError)

        sut.simulateErrorViewTap()
        XCTAssertEqual(sut.errorMessage, nil)
    }
}

private extension CommentsUIIntegrationTests {
    func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: ListViewController, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = CommentsUIComposer.commentsComposedWith(commentsLoader: loader.loadPublisher)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader)
    }

    func makeComment(message: String = "any message", username: String = "any username") -> ImageComment {
        ImageComment(id: UUID(), message: message, createdAt: Date(), username: username)
    }

    func assertThat(_ sut: ListViewController, isRendering comments: [ImageComment], file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(sut.numberOfRenderedComments, comments.count, "comments count", file: file, line: line)

        let viewModel = ImageCommentsPresenter.map(comments)

        viewModel.comments.enumerated().forEach { index, comment in
            XCTAssertEqual(sut.commentMessage(at: index), comment.message, "message at \(index)", file: file, line: line)
            XCTAssertEqual(sut.commentDate(at: index), comment.date, "date at \(index)", file: file, line: line)
            XCTAssertEqual(sut.commentUsername(at: index), comment.username, "username at \(index)", file: file, line: line)
        }
    }

    class LoaderSpy {
        private var requests = [PassthroughSubject<[ImageComment], Error>]()

        var loadCommentsCallCount: Int {
            requests.count
        }

        func loadPublisher() -> AnyPublisher<[ImageComment], Error> {
            let publisher = PassthroughSubject<[ImageComment], Error>()
            requests.append(publisher)
            return publisher.eraseToAnyPublisher()
        }

        func completeCommentsLoading(with comments: [ImageComment] = [], at index: Int = 0) {
            requests[index].send(comments)
        }

        func completeFeedLoadingWithError(at index: Int = 0) {
            let error = NSError(domain: "an error", code: 0)
            requests[index].send(completion: .failure(error))
        }
    }
}
