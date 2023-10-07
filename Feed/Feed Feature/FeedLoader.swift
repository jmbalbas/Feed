//
//  FeedLoader.swift
//  Feed
//
//  Created by Juan Santiago Martín Balbás on 3/12/22.
//

import Foundation

public protocol FeedLoader {
    typealias Result = (Swift.Result<[FeedImage], Error>)

    func load(completion: @escaping (Result) -> Void)
}
