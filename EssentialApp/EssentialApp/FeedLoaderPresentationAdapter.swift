//
//  FeedLoaderPresentationAdapter.swift
//  FeediOS
//
//  Created by Juan Santiago Martín Balbás on 22/10/23.
//

import Combine
import Feed
import FeediOS

final class FeedLoaderPresentationAdapter: FeedViewControllerDelegate {
    private let feedLoader: FeedLoader.Publisher
    private var cancellable: AnyCancellable?
    var presenter: FeedPresenter?

    init(feedLoader: FeedLoader.Publisher) {
        self.feedLoader = feedLoader
    }

    func didRequestFeedRefresh() {
        presenter?.didStartLoadingFeed()

        cancellable = feedLoader.sink { [weak self] completion in
            switch completion {
            case .finished:
                break
            case let .failure(error):
                self?.presenter?.didFinishLoadingFeed(with: error)
            }
        } receiveValue: { [weak self] feed in
            self?.presenter?.didFinishLoadingFeed(with: feed)
        }
    }
}
