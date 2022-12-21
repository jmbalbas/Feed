//
//  FeedLoader.swift
//  Feed
//
//  Created by Juan Santiago Martín Balbás on 3/12/22.
//

import Foundation

public protocol FeedLoader {
    func load() async throws -> [FeedItem]
}
