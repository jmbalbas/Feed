//
//  HTTPClientSpy.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 2/11/23.
//

import Feed
import Foundation

class HTTPClientSpy: HTTPClient {
    private struct Task: HTTPClientTask {
        let callback: () -> Void
        func cancel() { callback() }
    }

    private(set) var cancelledURLs = [URL]()
    private var messages = [(url: URL, completion: (HTTPClient.Result) -> Void)]()

    var requestedURLs: [URL] {
        messages.map(\.url)
    }

    func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) -> HTTPClientTask {
        messages.append((url, completion))
        return Task { [weak self] in
            self?.cancelledURLs.append(url)
        }
    }

    func complete(with error: Error, at index: Int = 0) {
        messages[index].completion(.failure(error))
    }

    func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
        let response = HTTPURLResponse(
            url: requestedURLs[index],
            statusCode: code,
            httpVersion: nil,
            headerFields: nil
        )!
        messages[index].completion(.success((data, response)))
    }
}
