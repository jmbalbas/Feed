//
//  FeedViewModel.swift
//  FeediOS
//
//  Created by Juan Santiago Martín Balbás on 14/10/23.
//

import Feed
import Foundation

final class FeedViewModel {
    private let feedLoader: FeedLoader
    private enum State {
        case pending
        case loading
    }

    private(set) var isLoading: Bool = false {
        didSet {
            onChange?(self)
        }
    }

    var onChange: ((FeedViewModel) -> Void)?
    var onFeedLoad: (([FeedImage]) -> Void)?

    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }

    func loadFeed() {
        isLoading = true
        feedLoader.load { [weak self] result in
            if let feed = try? result.get() {
                self?.onFeedLoad?(feed)
            }
            self?.isLoading = false
        }
    }
}
