//
//  FeedImageDataLoaderSpy.swift
//  EssentialAppTests
//
//  Created by Juan Santiago Martín Balbás on 5/11/23.
//

import Feed
import Foundation

class FeedImageDataLoaderSpy: FeedImageDataLoader {
    private var messages = [(url: URL, completion: (FeedImageDataLoader.Result) -> Void)]()

    private(set) var cancelledURLs = [URL]()

    var loadedURLs: [URL] {
        messages.map { $0.url }
    }

    private struct Task: FeedImageDataLoaderTask {
        let callback: () -> Void
        func cancel() { callback() }
    }

    func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result) -> Void) -> FeedImageDataLoaderTask {
        messages.append((url, completion))
        return Task { [weak self] in
            self?.cancelledURLs.append(url)
        }
    }

    func complete(with error: Error, at index: Int = 0) {
        messages[index].completion(.failure(error))
    }

    func complete(with data: Data, at index: Int = 0) {
        messages[index].completion(.success(data))
    }
}
