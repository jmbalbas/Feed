//
//  CacheFeedUseCase.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 10/1/23.
//

import Foundation
import XCTest

class FeedStore {
    private(set) var deleteCachedFeedCallCount: Int = 0
}

class LocalFeedStore {
    init(store: FeedStore) {

    }
}

class CacheFeedUseCase: XCTestCase {

    func test_init_doesNotDeleteCacheUponCreation() {
        let store = FeedStore()
        _ = LocalFeedStore(store: store)
        
        XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
    }

}
