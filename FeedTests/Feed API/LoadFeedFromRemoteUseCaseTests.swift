//
//  LoadFeedFromRemoteUseCaseTests.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 3/12/22.
//

import Foundation
import XCTest
import Feed

class LoadFeedFromRemoteUseCaseTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() async {
        let (_, client) = givenSUT()

        let requestedURLs = await client.requestedURLs
        XCTAssertTrue(requestedURLs.isEmpty)
    }

    func test_load_requestsDataFromURL() async {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = givenSUT(url: url)

        let task = whenCallingLoad(on: sut)
        complete(using: client)
        _ = try? await task.value

        let requestedURLs = await client.requestedURLs
        XCTAssertEqual(requestedURLs, [url])
    }

    func test_loadTwice_requestsDataFromURLTwice() async {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = givenSUT(url: url)

        for index in 0...1 {
            let task = whenCallingLoad(on: sut)
            complete(using: client, at: index)
            _ = try? await task.value
        }

        let requestedURLs = await client.requestedURLs
        XCTAssertEqual(requestedURLs, [url, url])
    }

    func test_load_deliversErrorOnClientError() async {
        let (sut, client) = givenSUT()

        await expect(sut, toCompleteWithError: .connectivity, when: {
            complete(withError: NSError(domain: "Test", code: 0), using: client)
        })
    }

    func test_load_deliversErrorOnNon200HTTPResponse() async throws {
        let (sut, client) = givenSUT()
        let json = try makeItemsJSON([])

        for (index, code) in [199, 201, 300, 400, 500].enumerated() {
            await expect(sut, toCompleteWithError: .invalidData, when: {
                complete(withStatusCode: code, data: json, using: client, at: index)
            })
        }
    }

    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() async {
        let (sut, client) = givenSUT()
        let invalidJSON = Data("Invalid json".utf8)

        await expect(sut, toCompleteWithError: .invalidData, when: {
            complete(withStatusCode: 200, data: invalidJSON, using: client)
        })
    }

    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() async throws {
        let (sut, client) = givenSUT()
        let emptyListJSON = try makeItemsJSON([])

        try await expect(sut, toCompleteWithItems: [], when: {
            complete(withStatusCode: 200, data: emptyListJSON, using: client)
        })
    }

    func test_load_deliversItemsOn200HTTPResponseWithJSONItems() async throws {
        let (sut, client) = givenSUT()

        let item1 = makeItem(id: UUID(), imageURL: URL(string: "http://a-url.com")!)
        let item2 = makeItem(id: UUID(), description: "A description", location: "A location", imageURL: URL(string: "http://another-url.com")!)
        let items = [item1, item2].map(\.model)
        let json = try makeItemsJSON([item1, item2].map(\.json))

        try await expect(sut, toCompleteWithItems: items, when: {
            complete(withStatusCode: 200, data: json, using: client)
        })
    }

}

// MARK: - Helpers

private extension LoadFeedFromRemoteUseCaseTests {

    func givenSUT(
        url: URL = URL(string: "https://a-url.com")!,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, client)
    }

    func whenCallingLoad(on sut: RemoteFeedLoader) -> Task<[FeedItem], Error> {
        Task(priority: .userInitiated) {
            try await sut.load()
        }
    }

    func complete(withError error: Error, using client: HTTPClientSpy, at index: Int = 0) {
        Task(priority: .background) {
            try await Task.sleep(nanoseconds: 1_000_00)
            return await client.complete(withError: error, at: index)
        }
    }

    func complete(withStatusCode code: Int = 200, data: Data = Data(), using client: HTTPClientSpy, at index: Int = 0) {
        Task(priority: .background) {
            try await Task.sleep(nanoseconds: 1_000_00)
            return await client.complete(withStatusCode: code, data: data, at: index)
        }
    }

    func expect(
        _ sut: RemoteFeedLoader,
        toCompleteWithItems items: [FeedItem],
        when action: () -> Void,
        line: UInt = #line
    ) async throws {
        let task = whenCallingLoad(on: sut)
        action()
        let retrievedItems = try await task.value
        XCTAssertEqual(items, retrievedItems, line: line)
    }

    func expect(
        _ sut: RemoteFeedLoader,
        toCompleteWithError error: RemoteFeedLoader.Error,
        when action: () -> Void,
        line: UInt = #line
    ) async {
        let task = whenCallingLoad(on: sut)
        action()
        await XCTAssertThrowsError(try await task.value, line: line) {
            XCTAssertEqual($0 as? RemoteFeedLoader.Error, error, line: line)
        }
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

private actor HTTPClientSpy: HTTPClient {

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
