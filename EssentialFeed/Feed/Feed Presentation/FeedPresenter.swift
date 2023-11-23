//
//  FeedPresenter.swift
//  Feed
//
//  Created by Juan Santiago Martín Balbás on 28/10/23.
//

import Foundation

public final class FeedPresenter {
    public static var title: String {
        NSLocalizedString(
            "FEED_VIEW_TITLE",
            tableName: "Feed",
            bundle: Bundle(for: Self.self),
            comment: "Title for the feed view"
        )
    }

    public static func map(_ feed: [FeedImage]) -> FeedViewModel {
        FeedViewModel(feed: feed)
    }
}
