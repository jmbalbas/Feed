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

    public func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(from: url)
        guard let httpURLResponse = response as? HTTPURLResponse else {
            throw Error.nonHTTPUrlResponse
        }
        return (data, httpURLResponse)
    }
}

public extension URLSessionHTTPClient {
    enum Error: Swift.Error {
        case nonHTTPUrlResponse
    }
}
