//
//  FeedLoaderStub.swift
//  EssentialAppTests
//
//  Created by Juan Santiago Martín Balbás on 5/11/23.
//

import Feed

class FeedLoaderStub: FeedLoader {
    private let result: FeedLoader.Result

    init(result: FeedLoader.Result) {
        self.result = result
    }

    func load(completion: @escaping (FeedLoader.Result) -> Void) {
        completion(result)
    }
}
