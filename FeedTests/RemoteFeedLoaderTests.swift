//
//  RemoteFeedLoaderTests.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 3/12/22.
//

import Foundation
import XCTest

class RemoteFeedLoader {
    let client: HTTPClient
    let url: URL

    init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }

    func load() {
        client.get(from: url)
    }
}

protocol HTTPClient {
    func get(from url: URL)
}

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

        XCTAssertNil(client.requestedURL)
    }

    func test_load_requestsDataFromURL() {
        let url = URL(string: "https://a-given-url.com")!
        let sut = givenSUT(url: url)

        sut.load()

        XCTAssertEqual(client.requestedURL, url)
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
    var requestedURL: URL?

    func get(from url: URL) {
        requestedURL = url
    }
}
