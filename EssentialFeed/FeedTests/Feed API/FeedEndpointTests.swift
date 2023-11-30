//
//  FeedEndpointTests.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 26/11/23.
//

import Feed
import XCTest

final class FeedEndpointTests: XCTestCase {
    func test_feed_endpointURL() {
        let baseURL = URL(string: "http://base-url.com")!

        let received = FeedEndpoint.get().url(baseURL: baseURL)

        XCTAssertEqual(received.scheme, "http", "scheme")
        XCTAssertEqual(received.host, "base-url.com", "host")
        XCTAssertEqual(received.path, "/v1/feed", "path")
        XCTAssertEqual(received.query, "limit=10", "query")
    }

    func test_feed_endpointURLAfterGivenImage() {
        let image = uniqueImage
        let baseURL = URL(string: "http://base-url.com")!

        let received = FeedEndpoint.get(after: image).url(baseURL: baseURL)

        XCTAssertEqual(received.scheme, "http", "scheme")
        XCTAssertEqual(received.host, "base-url.com", "host")
        XCTAssertEqual(received.path, "/v1/feed", "path")
        let query = received.query
        XCTAssertEqual(query?.contains("limit=10"), true, "limit query param")
        XCTAssertEqual(query?.contains("after_id=\(image.id)"), true, "after_id query param")

    }
}
