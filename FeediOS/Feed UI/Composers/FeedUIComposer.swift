//
//  FeedUIComposer.swift
//  FeediOS
//
//  Created by Juan Santiago Martín Balbás on 14/10/23.
//

import Feed
import UIKit

public enum FeedUIComposer {
    public static func feedComposedWith(feedLoader: FeedLoader, imageLoader: FeedImageDataLoader) -> FeedViewController {
        let presentationAdapter = FeedLoaderPresentationAdapter(
            feedLoader: MainQueueDispatchDecorator(decoratee: feedLoader)
        )

        let feedController = makeFeedViewController(delegate: presentationAdapter, title: FeedPresenter.title)

        let feedPresenter = FeedPresenter(
            feedView: FeedViewAdapter(
                controller: feedController,
                loader: MainQueueDispatchDecorator(decoratee: imageLoader)
            ),
            loadingView: WeakRefVirtualProxy(feedController)
        )
        presentationAdapter.presenter = feedPresenter
        return feedController
    }
}

extension FeedUIComposer {
    static func makeFeedViewController(delegate: FeedViewControllerDelegate, title: String) -> FeedViewController {
        let bundle = Bundle(for: FeedViewController.self)
        let storyboard = UIStoryboard(name: "Feed", bundle: bundle)
        let feedController = storyboard.instantiateInitialViewController() as! FeedViewController
        feedController.title = title
        feedController.delegate = delegate
        return feedController
    }
}
