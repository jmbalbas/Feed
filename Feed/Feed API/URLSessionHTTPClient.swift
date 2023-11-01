//
//  URLSessionHTTPClient.swift
//  Feed
//
//  Created by Juan Santiago Martín Balbás on 30/12/22.
//

import Foundation

public class URLSessionHTTPClient: HTTPClient {
    let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
        session.dataTask(with: url) { data, response, error in
            completion(Result {
                if let error {
                    throw error
                } else if let data, let response = response as? HTTPURLResponse {
                    return (data, response)
                } else {
                    throw Error.nonHTTPUrlResponse
                }
            })
        }.resume()
    }
}

public extension URLSessionHTTPClient {
    enum Error: Swift.Error {
        case nonHTTPUrlResponse
    }
}
