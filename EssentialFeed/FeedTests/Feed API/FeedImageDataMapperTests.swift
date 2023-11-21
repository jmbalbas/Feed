//
//  FeedImageDataMapperTests.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 21/11/23.
//

import Feed
import Foundation
import XCTest

final class FeedImageDataMapperTests: XCTestCase {
    func test_map_throwsErrorOnNon200HTTPResponse() throws {
        let nonEmptyData = Data("non-empty data".utf8)

        try [199, 201, 300, 400, 500].forEach { code in
            XCTAssertThrowsError(try FeedImageDataMapper.map(nonEmptyData, from: HTTPURLResponse(statusCode: code)))
        }
    }

    func test_map_throwsErrorOn200HTTPResponseWithEmptyData() {
        let emptyData = Data()

        XCTAssertThrowsError(try FeedImageDataMapper.map(emptyData, from: HTTPURLResponse(statusCode: 200)))
    }

    func test_map_deliversReceivedNonEmptyDataOn200HTTPResponse() throws {
        let nonEmptyData = Data("non-empty data".utf8)

        XCTAssertEqual(try FeedImageDataMapper.map(nonEmptyData, from: HTTPURLResponse(statusCode: 200)), nonEmptyData)
    }
}
