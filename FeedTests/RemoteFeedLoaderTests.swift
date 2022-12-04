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
    private var sut: RemoteFeedLoader!

    override func setUp() {
        super.setUp()
        client = .init()
    }

    override func tearDown() {
        client = nil
        sut = nil
        super.tearDown()
    }

    func test_init_doesNotRequestDataFromURL() {
        givenSUT()

        XCTAssertTrue(client.requestedURLs.isEmpty)
    }

    func test_load_requestsDataFromURL() throws {
        let url = URL(string: "https://a-given-url.com")!
        givenSUT(url: url)

        try whenCallingLoad()

        XCTAssertEqual(client.requestedURLs, [url])
    }

    func test_loadTwice_requestsDataFromURLTwice() throws {
        let url = URL(string: "https://a-given-url.com")!
        givenSUT(url: url)

        try whenCallingLoad()
        try whenCallingLoad()

        XCTAssertEqual(client.requestedURLs, [url, url])
    }

    func test_load_deliversErrorOnClientError() {
        givenSUT()
        let expectedError: RemoteFeedLoader.Error = .connectivity
        client.error = expectedError

        XCTAssertThrowsError(try whenCallingLoad()) {
            XCTAssertEqual($0 as? RemoteFeedLoader.Error, expectedError)
        }
    }

}

// MARK: - Helpers

private extension RemoteFeedLoaderTests {

    func givenSUT(url: URL = URL(string: "https://a-url.com")!) {
        sut = RemoteFeedLoader(client: client, url: url)
    }

    func whenCallingLoad() throws {
        try sut.load()
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
