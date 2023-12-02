//
//  FeedCache.swift
//  Feed
//
//  Created by Juan Santiago Martín Balbás on 5/11/23.
//

public protocol FeedCache {
    func save(_ feed: [FeedImage]) throws
}
