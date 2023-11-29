//
//  FeedUIIntegrationTests+LoaderSpy.swift
//  FeediOSTests
//
//  Created by Juan Santiago Martín Balbás on 14/10/23.
//

import Combine
import Feed
import FeediOS
import Foundation

extension FeedUIIntegrationTests {
    class LoaderSpy: FeedImageDataLoader {
        // MARK: - FeedLoader
        private var feedRequests = [PassthroughSubject<Paginated<FeedImage>, Error>]()

        var loadFeedCallCount: Int {
            feedRequests.count
        }

        func loadPublisher() -> AnyPublisher<Paginated<FeedImage>, Error> {
            let publisher = PassthroughSubject<Paginated<FeedImage>, Error>()
            feedRequests.append(publisher)
            return publisher.eraseToAnyPublisher()
        }

        func completeFeedLoading(with feed: [FeedImage] = [], at index: Int = 0) {
            feedRequests[index].send(Paginated(items: feed, loadMorePublisher: { [weak self] in
                self?.loadMorePublisher() ?? Empty().eraseToAnyPublisher()
            }))
        }

        func completeFeedLoadingWithError(at index: Int) {
            feedRequests[index].send(completion: .failure(anyNSError))
        }

        // MARK: - LoadMoreFeedLoader

        private var loadMoreRequests = [PassthroughSubject<Paginated<FeedImage>, Error>]()

        var loadMoreCallCount: Int {
            loadMoreRequests.count
        }

        func loadMorePublisher() -> AnyPublisher<Paginated<FeedImage>, Error> {
            let publisher = PassthroughSubject<Paginated<FeedImage>, Error>()
            loadMoreRequests.append(publisher)
            return publisher.eraseToAnyPublisher()
        }

        func completeLoadMore(with feed: [FeedImage] = [], lastPage: Bool = false, at index: Int = 0) {
            loadMoreRequests[index].send(Paginated(
                items: feed,
                loadMorePublisher: lastPage ? nil : { [weak self] in
                    self?.loadMorePublisher() ?? Empty().eraseToAnyPublisher()
                }))
        }

        func completeLoadMoreWithError(at index: Int = 0) {
            loadMoreRequests[index].send(completion: .failure(anyNSError))
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

}
