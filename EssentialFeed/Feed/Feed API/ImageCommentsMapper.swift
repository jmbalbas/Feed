//
//  ImageCommentsMapper.swift
//  Feed
//
//  Created by Juan Santiago Martín Balbás on 16/11/23.
//

import Foundation

enum ImageCommentsMapper {
    private struct Root: Decodable {
        let items: [RemoteFeedItem]
    }

    static func map(_ data: Data, from response: HTTPURLResponse) throws -> [RemoteFeedItem] {
        guard response.isOK, let feed = try? JSONDecoder().decode(Root.self, from: data).items else {
            throw RemoteImageCommentsLoader.Errors.invalidData
        }
        return feed
    }
}
