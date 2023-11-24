//
//  FeedViewController+TestHelper.swift
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

    func simulateUserInitiatedFeedReload() {
        refreshControl?.simulatePullToRefresh()
    }

    var numberOfRenderedFeedImageViews: Int {
        tableView.numberOfSections == 0 ? 0 :  tableView.numberOfRows(inSection: feedImagesSection)
    }

    var feedImagesSection: Int {
        0
    }

    func renderedFeedImageData(at index: Int) -> Data? {
        simulateFeedImageViewVisible(at: index)?.renderedImage
    }

    func feedImageView(at row: Int) -> UITableViewCell? {
        guard numberOfRenderedFeedImageViews > row else {
            return nil
        }
        let indexPath = IndexPath(row: row, section: feedImagesSection)
        return tableView.dataSource?.tableView(tableView, cellForRowAt: indexPath)
    }

    @discardableResult
    func simulateFeedImageViewVisible(at index: Int) -> FeedImageCell? {
        feedImageView(at: index) as? FeedImageCell
    }

    @discardableResult
    func simulateFeedImageViewNotVisible(at row: Int) -> FeedImageCell {
        let view = simulateFeedImageViewVisible(at: row)!

        let indexPath = IndexPath(row: row, section: feedImagesSection)
        tableView.delegate?.tableView?(tableView, didEndDisplaying: view, forRowAt: indexPath)

        return view
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
