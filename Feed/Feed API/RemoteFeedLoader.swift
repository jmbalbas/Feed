//
//  RemoteFeedLoader.swift
//  Feed
//
//  Created by Juan Santiago Martín Balbás on 4/12/22.
//

import Foundation

public protocol HTTPClient {
    func get(from url: URL) async throws -> (Data, HTTPURLResponse)
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

    public func load() async throws -> [FeedItem] {
        let data: Data
        let response: HTTPURLResponse

        do {
            (data, response) = try await client.get(from: url)
        } catch {
            throw Error.connectivity
        }

        guard response.statusCode == 200 else {
            throw Error.invalidData
        }

        do {
            let _ = try JSONDecoder().decode([String: [String]].self, from: data)
            return []
        } catch {
            throw Error.invalidData
        }

    }

}
