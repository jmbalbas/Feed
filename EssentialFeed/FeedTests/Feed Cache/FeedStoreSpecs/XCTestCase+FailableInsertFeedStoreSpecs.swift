//
//  XCTestCase+FailableInsertFeedStoreSpecs.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 2/11/23.
//

import Feed
import XCTest

extension FailableInsertFeedStoreSpecs where Self: XCTestCase {
	func assertThatInsertDeliversErrorOnInsertionError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        XCTAssertThrowsError(
            try insert((uniqueImageFeed.local, Date()), to: sut),
            "Expected cache insertion to fail with an error",
            file: file,
            line: line
        )
	}
	
	func assertThatInsertHasNoSideEffectsOnInsertionError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
		try? insert((uniqueImageFeed.local, Date()), to: sut)

        expect(sut, toRetrieve: .success(.none), file: file, line: line)
	}
}
