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
        client.stub(error: expectedError)

        XCTAssertThrowsError(try whenCallingLoad()) {
            XCTAssertEqual($0 as? RemoteFeedLoader.Error, expectedError)
        }
    }

    func test_load_deliversErrorOnNon200HTTPResponse() {
        givenSUT()

        for code in [199, 201, 300, 400, 500] {
            client.stub(statusCode: code)

            XCTAssertThrowsError(try whenCallingLoad()) {
                XCTAssertEqual($0 as? RemoteFeedLoader.Error, .invalidData)
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
    private var result: Result<Int, Error> = .success(200)

    func get(from url: URL) throws -> HTTPURLResponse {
        requestedURLs.append(url)
        switch result {
        case .success(let statusCode):
            return HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        case .failure(let error):
            throw error
        }
    }

    func stub(error: Error) {
        result = .failure(error)
    }

    func stub(statusCode: Int) {
        result = .success(statusCode)
    }
}
