//
//  FeedCache.swift
//  Feed
//
//  Created by Juan Santiago Martín Balbás on 5/11/23.
//

public protocol FeedCache {
    typealias Result = Swift.Result<Void, Error>

    func save(_ feed: [FeedImage], completion: @escaping (Result) -> Void)
}
