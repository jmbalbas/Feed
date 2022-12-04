//
//  RemoteFeedLoader.swift
//  Feed
//
//  Created by Juan Santiago Martín Balbás on 4/12/22.
//

import Foundation

public protocol HTTPClient {
    func get(from url: URL) throws -> HTTPURLResponse
}

public final class RemoteFeedLoader {
    private let client: HTTPClient
    private let url: URL

    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    public init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }

    public func load() throws {
        do {
            _ = try client.get(from: url)
        } catch {
            throw Error.connectivity
        }

        throw Error.invalidData
    }
}
