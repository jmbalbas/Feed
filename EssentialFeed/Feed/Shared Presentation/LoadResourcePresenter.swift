//
//  LoadResourcePresenter.swift
//  Feed
//
//  Created by Juan Santiago Martín Balbás on 22/11/23.
//

import Foundation

public final class LoadResourcePresenter {
    private let feedView: FeedView
    private let errorView: FeedErrorView
    private let loadingView: FeedLoadingView

    public static var title: String {
        NSLocalizedString(
            "FEED_VIEW_TITLE",
            tableName: "Feed",
            bundle: Bundle(for: Self.self),
            comment: "Title for the feed view"
        )
    }

    private var feedLoadError: String {
        NSLocalizedString(
            "FEED_VIEW_CONNECTION_ERROR",
             tableName: "Feed",
             bundle: Bundle(for: Self.self),
             comment: "Error message displayed when we can't load the image feed from the server"
        )
    }

    public init(feedView: FeedView, loadingView: FeedLoadingView, errorView: FeedErrorView) {
        self.feedView = feedView
        self.loadingView = loadingView
        self.errorView = errorView
    }

    public func didStartLoadingFeed() {
        errorView.display(.noError)
        loadingView.display(FeedLoadingViewModel(isLoading: true))
    }

    public func didFinishLoadingFeed(with feed: [FeedImage]) {
        feedView.display(FeedViewModel(feed: feed))
        loadingView.display(FeedLoadingViewModel(isLoading: false))
    }

    public func didFinishLoadingFeed(with error: Error) {
        errorView.display(.error(message: feedLoadError))
        loadingView.display(FeedLoadingViewModel(isLoading: false))
    }
}
