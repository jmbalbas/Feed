//
//  URLSessionHTTPClient.swift
//  Feed
//
//  Created by Juan Santiago Martín Balbás on 30/12/22.
//

import Foundation

public final class URLSessionHTTPClient: HTTPClient {
    let session: URLSession

    public init(session: URLSession) {
        self.session = session
    }

    private struct URLSessionTaskWrapper: HTTPClientTask {
        let wrapped: URLSessionTask

        func cancel() {
            wrapped.cancel()
        }
    }

    public func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) -> HTTPClientTask {
        let task = session.dataTask(with: url) { data, response, error in
            completion(Result {
                if let error {
                    throw error
                } else if let data, let response = response as? HTTPURLResponse {
                    return (data, response)
                } else {
                    throw Error.nonHTTPUrlResponse
                }
            })
        }
        task.resume()
        return URLSessionTaskWrapper(wrapped: task)
    }
}

public extension URLSessionHTTPClient {
    enum Error: Swift.Error {
        case nonHTTPUrlResponse
    }
}
