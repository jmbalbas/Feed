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

    func test_load_requestsDataFromURL() async {
        let url = URL(string: "https://a-given-url.com")!
        givenSUT(url: url)

        try? await whenCallingLoad()

        XCTAssertEqual(client.requestedURLs, [url])
    }

    func test_loadTwice_requestsDataFromURLTwice() async {
        let url = URL(string: "https://a-given-url.com")!
        givenSUT(url: url)

        try? await whenCallingLoad(at: 0)
        try? await whenCallingLoad(at: 1)

        XCTAssertEqual(client.requestedURLs, [url, url])
    }

    func test_load_deliversErrorOnClientError() async {
        givenSUT()

        await expectToComplete(withError: .connectivity, when: {
            try await self.whenCallingLoad(completingWithError: NSError(domain: "Test", code: 0))
        })
    }

    func test_load_deliversErrorOnNon200HTTPResponse() async {
        givenSUT()

        for (index, code) in [199, 201, 300, 400, 500].enumerated() {
            await expectToComplete(withError: .invalidData, when: {
                try await whenCallingLoad(completingWithStatusCode: code, at: index)
            })
        }
    }

    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() async {
        givenSUT()
        let invalidJSON = Data("Invalid json".utf8)

        await expectToComplete(withError: .invalidData, when: {
            try await whenCallingLoad(completingWithStatusCode: 200, data: invalidJSON)
        })
    }
}

// MARK: - Helpers

private extension RemoteFeedLoaderTests {

    func givenSUT(url: URL = URL(string: "https://a-url.com")!) {
        sut = RemoteFeedLoader(client: client, url: url)
    }

    func whenCallingLoad(completingWithStatusCode code: Int = 200, data: Data = Data(), at index: Int = 0) async throws {
        Task {
            try await Task.sleep(nanoseconds: 1_000_000)
            client.complete(withStatusCode: code, data: data, at: index)
        }
        _ = try await sut.load()
    }

    func whenCallingLoad(completingWithError error: Error, at index: Int = 0) async throws {
        Task {
            try await Task.sleep(nanoseconds: 1_000_000)
            self.client.complete(withError: error, at: index)
        }
        _ = try await sut.load()
    }

    func expectToComplete(withError error: RemoteFeedLoader.Error, when action: () async throws -> Void, line: UInt = #line) async {
        await XCTAssertThrowsError(try await action(), line: line) {
            XCTAssertEqual($0 as? RemoteFeedLoader.Error, error, line: line)
        }
    }
}

// MARK: - HTTPClientSpy

private class HTTPClientSpy: HTTPClient {
    var requestedURLs: [URL] {
        messages.map { $0.url }
    }

    private var messages: [(url: URL, continuation: CheckedContinuation<(Data, HTTPURLResponse), Error>)] = []

    func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
        try await withCheckedThrowingContinuation {
            messages.append((url: url, continuation: $0))
        }
    }

    func complete(withError error: Error, at index: Int = 0) {
        messages[index].continuation.resume(throwing: error)
    }

    func complete(withStatusCode code: Int = 200, data: Data = Data(), at index: Int = 0) {
        let message = messages[index]
        message.continuation.resume(
            returning: (data, .init(url: message.url, statusCode: code, httpVersion: nil, headerFields: nil)!)
        )
    }
}
