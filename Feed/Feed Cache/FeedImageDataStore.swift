//
//  FeedImageDataStore.swift
//  Feed
//
//  Created by Juan Santiago Martín Balbás on 2/11/23.
//

import Foundation

public protocol FeedImageDataStore {
    typealias Result = Swift.Result<Data?, Error>

    func retrieve(dataForURL url: URL, completion: @escaping (Result) -> Void)
}
