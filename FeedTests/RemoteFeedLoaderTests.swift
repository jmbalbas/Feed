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

    func test_load_requestsDataFromURL() throws {
        let url = URL(string: "https://a-given-url.com")!
        let sut = givenSUT(url: url)

        try sut.load()

        XCTAssertEqual(client.requestedURLs, [url])
    }

    func test_loadTwice_requestsDataFromURLTwice() throws {
        let url = URL(string: "https://a-given-url.com")!
        let sut = givenSUT(url: url)

        try sut.load()
        try sut.load()

        XCTAssertEqual(client.requestedURLs, [url, url])
    }

    func test_load_deliversErrorOnClientError() {
        let sut = givenSUT()
        let expectedError: RemoteFeedLoader.Error = .connectivity
        client.error = expectedError

        XCTAssertThrowsError(try sut.load()) {
            XCTAssertEqual($0 as? RemoteFeedLoader.Error, expectedError)
        }
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
    var error: RemoteFeedLoader.Error?

    func get(from url: URL) throws {
        requestedURLs.append(url)
        if let error = error {
            throw error
        }
    }
}
