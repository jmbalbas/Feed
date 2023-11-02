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

    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = givenSUT()

        XCTAssert(client.requestedURLs.isEmpty)
    }

    func test_load_requestsDataFromURL() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = givenSUT(url: url)

        whenCallingLoad(on: sut)

        XCTAssertEqual(client.requestedURLs, [url])
    }

    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = givenSUT(url: url)
        
        whenCallingLoad(on: sut)
        whenCallingLoad(on: sut)

        XCTAssertEqual(client.requestedURLs, [url, url])
    }

    func test_load_deliversErrorOnClientError() {
        let (sut, client) = givenSUT()

        expect(sut, toCompleteWithError: .connectivity, when: {
            complete(withError: NSError(domain: "Test", code: 0), using: client)
        })
    }

    func test_load_deliversErrorOnNon200HTTPResponse() throws {
        let (sut, client) = givenSUT()
        let json = try makeItemsJSON([])

        for (index, code) in [199, 201, 300, 400, 500].enumerated() {
            expect(sut, toCompleteWithError: .invalidData, when: {
                complete(withStatusCode: code, data: json, using: client, at: index)
            })
        }
    }

    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = givenSUT()
        let invalidJSON = Data("Invalid json".utf8)

        expect(sut, toCompleteWithError: .invalidData, when: {
            complete(withStatusCode: 200, data: invalidJSON, using: client)
        })
    }

    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() throws {
        let (sut, client) = givenSUT()
        let emptyListJSON = try makeItemsJSON([])

        expect(sut, toCompleteWithItems: [], when: {
            complete(withStatusCode: 200, data: emptyListJSON, using: client)
        })
    }

    func test_load_deliversItemsOn200HTTPResponseWithJSONItems() throws {
        let (sut, client) = givenSUT()

        let item1 = makeItem(id: UUID(), imageURL: URL(string: "http://a-url.com")!)
        let item2 = makeItem(id: UUID(), description: "A description", location: "A location", imageURL: URL(string: "http://another-url.com")!)
        let items = [item1, item2].map(\.model)
        let json = try makeItemsJSON([item1, item2].map(\.json))

        expect(sut, toCompleteWithItems: items, when: {
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

    func whenCallingLoad(on sut: RemoteFeedLoader, completion: @escaping (FeedLoader.Result) -> Void = { _ in }) {
        sut.load(completion: completion)
    }

    func complete(withError error: Error, using client: HTTPClientSpy, at index: Int = 0) {
        client.complete(with: error, at: index)
    }

    func complete(withStatusCode code: Int = 200, data: Data = Data(), using client: HTTPClientSpy, at index: Int = 0) {
        client.complete(withStatusCode: code, data: data, at: index)
    }

    func expect(
        _ sut: RemoteFeedLoader,
        toCompleteWithItems expectedItems: [FeedImage],
        when action: () -> Void,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for load completion")
        whenCallingLoad(on: sut) { receivedResult in
            switch receivedResult {
            case let .success(receivedItems):
                XCTAssertEqual(receivedItems, expectedItems, line: line)
            default:
                XCTFail("Expected items \(expectedItems) got \(receivedResult) instead", line: line)
            }
            exp.fulfill()
        }
        action()
        wait(for: [exp], timeout: 1.0)
    }

    func expect(
        _ sut: RemoteFeedLoader,
        toCompleteWithError expectedError: RemoteFeedLoader.Errors,
        when action: () -> Void,
        line: UInt = #line
    )  {
        let exp = expectation(description: "Wait for load completion")
        whenCallingLoad(on: sut) { receivedResult in
            switch receivedResult {
            case let .failure(error):
                XCTAssertEqual(error as? RemoteFeedLoader.Errors, expectedError, line: line)
            default:
                XCTFail("Expected error \(expectedError) got \(receivedResult) instead", line: line)
            }
            exp.fulfill()
        }
        action()
        wait(for: [exp], timeout: 1.0)
    }

    func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) -> (model: FeedImage, json: [String: Any]) {
        let item = FeedImage(id: id, description: description, location: location, url: imageURL)
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
