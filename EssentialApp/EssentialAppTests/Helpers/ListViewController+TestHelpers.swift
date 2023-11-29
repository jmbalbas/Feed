//
//  ListViewController+TestHelper.swift
//  FeediOSTests
//
//  Created by Juan Santiago Martín Balbás on 14/10/23.
//

import FeediOS
import UIKit

extension ListViewController {
    func simulateAppearance() {
        if !isViewLoaded {
            loadViewIfNeeded()
            prepareForFirstAppearance()
        }

        beginAppearanceTransition(true, animated: false)
        endAppearanceTransition()
    }

    public override func loadViewIfNeeded() {
        super.loadViewIfNeeded()

        tableView.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
    }

    var isShowingLoadingIndicator: Bool {
        refreshControl?.isRefreshing == true
    }

    func simulateErrorViewTap() {
        errorView.simulateTap()
    }

    var errorMessage: String? {
        errorView.message
    }

    func numberOfRows(in section: Int) -> Int {
        tableView.numberOfSections > section ? tableView.numberOfRows(inSection: section) : 0
    }

    func cell(row: Int, section: Int) -> UITableViewCell? {
        guard numberOfRows(in: section) > row else {
            return nil
        }
        let dataSource = tableView.dataSource
        let index = IndexPath(row: row, section: section)
        return dataSource?.tableView(tableView, cellForRowAt: index)
    }
}

extension ListViewController {
    var numberOfRenderedComments: Int {
        numberOfRows(in: commentsSection)
    }

    func commentMessage(at row: Int) -> String? {
        commentView(at: row)?.messageLabel.text
    }

    func commentDate(at row: Int) -> String? {
        commentView(at: row)?.dateLabel.text
    }

    func commentUsername(at row: Int) -> String? {
        commentView(at: row)?.usernameLabel.text
    }

    private func commentView(at row: Int) -> ImageCommentCell? {
        cell(row: row, section: commentsSection) as? ImageCommentCell
    }

    private var commentsSection: Int { 0 }
}

extension ListViewController {
    func simulateUserInitiatedReload() {
        refreshControl?.simulatePullToRefresh()
    }

    var numberOfRenderedFeedImageViews: Int {
        numberOfRows(in: feedImagesSection)
    }

    private var feedImagesSection: Int { 0 }

    private var feedLoadMoreSection: Int { 1 }

    func renderedFeedImageData(at index: Int) -> Data? {
        simulateFeedImageViewVisible(at: index)?.renderedImage
    }

    func feedImageView(at row: Int) -> UITableViewCell? {
        cell(row: row, section: feedImagesSection)
    }

    @discardableResult
    func simulateFeedImageViewVisible(at index: Int) -> FeedImageCell? {
        feedImageView(at: index) as? FeedImageCell
    }

    @discardableResult
    func simulateFeedImageBecomingVisibleAgain(at row: Int) -> FeedImageCell? {
        let view = simulateFeedImageViewNotVisible(at: row)

        let delegate = tableView.delegate
        let index = IndexPath(row: row, section: feedImagesSection)
        delegate?.tableView?(tableView, willDisplay: view, forRowAt: index)

        return view
    }

    @discardableResult
    func simulateFeedImageViewNotVisible(at row: Int) -> FeedImageCell {
        let view = simulateFeedImageViewVisible(at: row)!

        let indexPath = IndexPath(row: row, section: feedImagesSection)
        tableView.delegate?.tableView?(tableView, didEndDisplaying: view, forRowAt: indexPath)

        return view
    }

    func simulateTapOnFeedImage(at row: Int) {
        let delegate = tableView.delegate
        let index = IndexPath(row: row, section: feedImagesSection)
        delegate?.tableView?(tableView, didSelectRowAt: index)
    }

    func simulateFeedImageViewNearVisible(at row: Int) {
        let indexPath = IndexPath(row: row, section: feedImagesSection)
        tableView.prefetchDataSource?.tableView(tableView, prefetchRowsAt: [indexPath])
    }

    func simulateFeedImageViewNotNearVisible(at row: Int) {
        simulateFeedImageViewNearVisible(at: row)

        let index = IndexPath(row: row, section: feedImagesSection)
        tableView.prefetchDataSource?.tableView?(tableView, cancelPrefetchingForRowsAt: [index])
    }

    func simulateLoadMoreFeedAction() {
        guard let view = loadMoreFeedCell else { return }

        let delegate = tableView.delegate
        let index = IndexPath(row: 0, section: feedLoadMoreSection)
        delegate?.tableView?(tableView, willDisplay: view, forRowAt: index)
    }

    func simulateTapOnLoadMoreFeedError() {
        let delegate = tableView.delegate
        let index = IndexPath(row: 0, section: feedLoadMoreSection)
        delegate?.tableView?(tableView, didSelectRowAt: index)
    }

    var isShowingLoadMoreFeedIndicator: Bool {
        loadMoreFeedCell?.isLoading == true
    }

    var loadMoreFeedErrorMessage: String? {
        loadMoreFeedCell?.message
    }

    private var loadMoreFeedCell: LoadMoreCell? {
        cell(row: 0, section: feedLoadMoreSection) as? LoadMoreCell
    }

    private func prepareForFirstAppearance() {
        replaceRefreshControlWithSpyForiOS17Support()
    }

    private func replaceRefreshControlWithSpyForiOS17Support() {
        let spyRefreshControl = UIRefreshControlSpy()

        refreshControl?.allTargets.forEach { target in
            refreshControl?.actions(forTarget: target, forControlEvent: .valueChanged)?.forEach { action in
                spyRefreshControl.addTarget(target, action: Selector(action), for: .valueChanged)
            }
        }

        refreshControl = spyRefreshControl
    }
}

private class UIRefreshControlSpy: UIRefreshControl {
    private var _isRefreshing = false

    override var isRefreshing: Bool { _isRefreshing }

    override func beginRefreshing() {
        _isRefreshing = true
    }

    override func endRefreshing() {
        _isRefreshing = false
    }
}
