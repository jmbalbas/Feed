//
//  RemoteFeedLoaderTests.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 3/12/22.
//

import Foundation
import XCTest
import Feed

class RemoteFeedLoaderTests: XCTestCase {

    private var client: HTTPClientSpy!

    override func setUp() {
        super.setUp()
        client = .init()
    }

    override func tearDown() {
        client = nil
        super.tearDown()
    }

    func test_init_doesNotRequestDataFromURL() {
        _ = givenSUT()

        XCTAssertTrue(client.requestedURLs.isEmpty)
    }

    func test_load_requestsDataFromURL() {
        let url = URL(string: "https://a-given-url.com")!
        let sut = givenSUT(url: url)

        sut.load()

        XCTAssertEqual(client.requestedURLs, [url])
    }

    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https://a-given-url.com")!
        let sut = givenSUT(url: url)

        sut.load()
        sut.load()

        XCTAssertEqual(client.requestedURLs, [url, url])
    }
}

// MARK: - Helpers

private extension RemoteFeedLoaderTests {

    func givenSUT(url: URL = URL(string: "https://a-url.com")!) -> RemoteFeedLoader {
        RemoteFeedLoader(client: client, url: url)
    }

}

// MARK: - HTTPClientSpy

private class HTTPClientSpy: HTTPClient {
    private(set) var requestedURLs: [URL] = []

    func get(from url: URL) {
        requestedURLs.append(url)
    }
}
