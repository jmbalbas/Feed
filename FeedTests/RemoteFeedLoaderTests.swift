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

        _ = try? await whenCallingLoad()

        XCTAssertEqual(client.requestedURLs, [url])
    }

    func test_loadTwice_requestsDataFromURLTwice() async {
        let url = URL(string: "https://a-given-url.com")!
        givenSUT(url: url)

        _ = try? await whenCallingLoad(at: 0)
        _ = try? await whenCallingLoad(at: 1)

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

    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() async throws {
        givenSUT()
        let emptyListJSON = Data("{\"items\": []}".utf8)

        try await expectToComplete(withItems: [], when: {
            try await whenCallingLoad(completingWithStatusCode: 200, data: emptyListJSON)
        })
    }

    func test_load_deliversItemsOn200HTTPResponseWithJSONItems() async throws {
        givenSUT()

        let item1 = makeItem(id: UUID(), imageURL: URL(string: "http://a-url.com")!)
        let item2 = makeItem(id: UUID(), description: "A description", location: "A location", imageURL: URL(string: "http://another-url.com")!)
        let items = [item1.model, item2.model]

        try await expectToComplete(withItems: items, when: {
            let json = [item1.json, item2.json]
            return try await whenCallingLoad(completingWithStatusCode: 200, data: makeItemsJSON(json))
        })
    }
}

// MARK: - Helpers

private extension RemoteFeedLoaderTests {

    func givenSUT(url: URL = URL(string: "https://a-url.com")!) {
        sut = RemoteFeedLoader(client: client, url: url)
    }

    @discardableResult
    func whenCallingLoad(completingWithStatusCode code: Int = 200, data: Data = Data(), at index: Int = 0) async throws -> [FeedItem]  {
        try await whenCallingLoad(
            completingWith: { self.client.complete(withStatusCode: code, data: data, at: index) },
            at: index
        )
    }

    @discardableResult
    func whenCallingLoad(completingWithError error: Error, at index: Int = 0) async throws -> [FeedItem]  {
        try await whenCallingLoad(
            completingWith: { self.client.complete(withError: error, at: index) },
            at: index
        )
    }

    func whenCallingLoad(completingWith action: @escaping () -> Void, at index: Int) async throws -> [FeedItem] {
        Task {
            try await Task.sleep(nanoseconds: 1_000_000)
            action()
        }
        return try await sut.load()
    }

    func expectToComplete(withError error: RemoteFeedLoader.Error, when action: () async throws -> Void, line: UInt = #line) async {
        await XCTAssertThrowsError(try await action(), line: line) {
            XCTAssertEqual($0 as? RemoteFeedLoader.Error, error, line: line)
        }
    }

    func expectToComplete(withItems items: [FeedItem], when action: () async throws -> [FeedItem], line: UInt = #line) async throws {
        let retrievedItems = try await action()
        XCTAssertEqual(items, retrievedItems, line: line)
    }

    func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) -> (model: FeedItem, json: [String: Any]) {
        let item = FeedItem(id: id, description: description, location: location, imageURL: imageURL)
        let json = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image": imageURL.absoluteString
        ].compactMapValues { $0 }
        return (model: item, json: json)
    }

    func makeItemsJSON(_ items: [[String: Any]]) throws -> Data {
        try JSONSerialization.data(withJSONObject: ["items": items])
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
