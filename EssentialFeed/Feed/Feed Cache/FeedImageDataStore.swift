//
//  FeedImageDataStore.swift
//  Feed
//
//  Created by Juan Santiago Martín Balbás on 2/11/23.
//

import Foundation

public protocol FeedImageDataStore {
    func insert(_ data: Data, for url: URL) throws
    func retrieve(dataForURL url: URL) throws -> Data?
}
