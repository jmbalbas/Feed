//
//  CodableFeedStoreTests.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 10/8/23.
//

import Feed
import XCTest

final class CodableFeedStore {
    func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
        completion(.empty)
    }
}

final class CodableFeedStoreTests: XCTestCase {
    func test_retrieve_deliversEmptyOnEmptyCache() async {
        let sut = CodableFeedStore()
        let expectation = expectation(description: "Wait for cache retrieval")
        
        sut.retrieve { result in
            switch result {
            case .empty:
                break
            default:
                XCTFail("Expected empty result, got \(result) instead")
            }
            
            expectation.fulfill()
        }
     
        await fulfillment(of: [expectation], timeout: 1)
    }
}
