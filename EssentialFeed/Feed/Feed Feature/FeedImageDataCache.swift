//
//  FeedImageDataCache.swift
//  Feed
//
//  Created by Juan Santiago Martín Balbás on 5/11/23.
//

import Foundation

public protocol FeedImageDataCache {
    typealias Result = Swift.Result<Void, Error>

    func save(_ data: Data, for url: URL, completion: @escaping (Result) -> Void)
}
