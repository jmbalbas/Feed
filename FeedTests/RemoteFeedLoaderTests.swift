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

    private var client: HTTPClientStub!
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

    func test_load_requestsDataFromURL() {
        let url = URL(string: "https://a-given-url.com")!
        givenSUT(url: url)

        try? whenCallingLoad()

        XCTAssertEqual(client.requestedURLs, [url])
    }

    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https://a-given-url.com")!
        givenSUT(url: url)

        try? whenCallingLoad()
        try? whenCallingLoad()

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

    func test_load_deliversErrorOnNon200HTTPResponse() {
        givenSUT()
        let expectedError: RemoteFeedLoader.Error = .invalidData

        for code in [199, 201, 300, 400, 500] {
            client.responseCode = code

            XCTAssertThrowsError(try whenCallingLoad()) {
                XCTAssertEqual($0 as? RemoteFeedLoader.Error, expectedError)
            }
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

private class HTTPClientStub: HTTPClient {
    private(set) var requestedURLs: [URL] = []
    var result: Result<Int, Error> = .success(200)
    var error: Error? {
        didSet {
            if let error = error {
                result = .failure(error)
            }
        }
    }
    var responseCode: Int = 200 {
        didSet {
            result = .success(responseCode)
        }
    }

    func get(from url: URL) throws -> HTTPURLResponse {
        requestedURLs.append(url)
        switch result {
        case .success(let statusCode):
            return HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        case .failure(let error):
            throw error
        }
    }
}
