//
//  RemoteImageCommentsLoader.swift
//  Feed
//
//  Created by Juan Santiago Martín Balbás on 16/11/23.
//

import Foundation

public final class RemoteImageCommentsLoader {
    private let client: HTTPClient
    private let url: URL

    public enum Errors: Error {
        case connectivity
        case invalidData
    }

    public init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }

    public typealias Result = Swift.Result<[ImageComment], Error>

    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { result in
            switch result {
            case let .success((data, response)):
                do {
                    let imageComments = try Self.map(data, from: response)
                    completion(.success(imageComments))
                } catch {
                    completion(.failure(error))
                }
            case .failure:
                completion(.failure(Errors.connectivity))
            }
        }
    }

    private static func map(_ data: Data, from response: HTTPURLResponse) throws -> [ImageComment] {
        try ImageCommentsMapper.map(data, from: response)
    }
}
