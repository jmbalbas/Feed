//
//  XCTestCase+FailableDeleteFeedStoreSpecs.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 2/11/23.
//

import Feed
import XCTest

extension FailableDeleteFeedStoreSpecs where Self: XCTestCase {
	func assertThatDeleteDeliversErrorOnDeletionError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        XCTAssertThrowsError(
            try deleteCache(from: sut),
            "Expected cache deletion to fail",
            file: file,
            line: line
        )
	}
	
	func assertThatDeleteHasNoSideEffectsOnDeletionError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
		try? deleteCache(from: sut)

        expect(sut, toRetrieve: .success(.none), file: file, line: line)
	}
}
