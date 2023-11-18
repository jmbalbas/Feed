//
//  LoadImageCommentsFromRemoteUseCaseTests.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 16/11/23.
//

import Feed
import XCTest

final class LoadImageCommentsFromRemoteUseCaseTests: XCTestCase {
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

    func test_load_deliversErrorOnNon2xxHTTPResponse() throws {
        let (sut, client) = givenSUT()
        let json = try makeItemsJSON([])

        for (index, code) in [199, 159, 300, 400, 500].enumerated() {
            expect(sut, toCompleteWithError: .invalidData, when: {
                complete(withStatusCode: code, data: json, using: client, at: index)
            })
        }
    }

    func test_load_deliversErrorOn2xxHTTPResponseWithInvalidJSON() {
        let (sut, client) = givenSUT()
        let invalidJSON = Data("Invalid json".utf8)

        for (index, code) in [200, 201, 250, 280, 299].enumerated() {
            expect(sut, toCompleteWithError: .invalidData, when: {
                complete(withStatusCode: code, data: invalidJSON, using: client, at: index)
            })
        }
    }

    func test_load_deliversNoItemsOn2xxHTTPResponseWithEmptyJSONList() throws {
        let (sut, client) = givenSUT()
        let emptyListJSON = try makeItemsJSON([])

        for (index, code) in [200, 201, 250, 280, 299].enumerated() {
            expect(sut, toCompleteWithItems: [], when: {
                complete(withStatusCode: code, data: emptyListJSON, using: client, at: index)
            })
        }
    }

    func test_load_deliversItemsOn2xxHTTPResponseWithJSONItems() throws {
        let (sut, client) = givenSUT()

        let item1 = makeItem(
            id: UUID(),
            message: "A message",
            createdAt: (Date(timeIntervalSince1970: 1598627222), "2020-08-28T15:07:02+00:00"),
            username: "A username"
        )
        let item2 = makeItem(
            id: UUID(),
            message: "Another message",
            createdAt: (Date(timeIntervalSince1970: 1577881882), "2020-01-01T12:31:22+00:00"),
            username: "Another username"
        )
        let items = [item1, item2].map(\.model)
        let json = try makeItemsJSON([item1, item2].map(\.json))

        for (index, code) in [200, 201, 250, 280, 299].enumerated() {
            expect(sut, toCompleteWithItems: items, when: {
                complete(withStatusCode: code, data: json, using: client, at: index)
            })
        }
    }

}

// MARK: - Helpers

private extension LoadImageCommentsFromRemoteUseCaseTests {

    func givenSUT(
        url: URL = URL(string: "https://a-url.com")!,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: RemoteImageCommentsLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteImageCommentsLoader(client: client, url: url)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, client)
    }

    func whenCallingLoad(on sut: RemoteImageCommentsLoader, completion: @escaping (RemoteImageCommentsLoader.Result) -> Void = { _ in }) {
        sut.load(completion: completion)
    }

    func complete(withError error: Error, using client: HTTPClientSpy, at index: Int = 0) {
        client.complete(with: error, at: index)
    }

    func complete(withStatusCode code: Int = 200, data: Data = Data(), using client: HTTPClientSpy, at index: Int = 0) {
        client.complete(withStatusCode: code, data: data, at: index)
    }

    func expect(
        _ sut: RemoteImageCommentsLoader,
        toCompleteWithItems expectedItems: [ImageComment],
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
        _ sut: RemoteImageCommentsLoader,
        toCompleteWithError expectedError: RemoteImageCommentsLoader.Errors,
        when action: () -> Void,
        line: UInt = #line
    )  {
        let exp = expectation(description: "Wait for load completion")
        whenCallingLoad(on: sut) { receivedResult in
            switch receivedResult {
            case let .failure(error):
                XCTAssertEqual(error as? RemoteImageCommentsLoader.Errors, expectedError, line: line)
            default:
                XCTFail("Expected error \(expectedError) got \(receivedResult) instead", line: line)
            }
            exp.fulfill()
        }
        action()
        wait(for: [exp], timeout: 1.0)
    }

    func makeItem(
        id: UUID,
        message: String,
        createdAt: (date: Date, iso8601String: String),
        username: String
    ) -> (model: ImageComment, json: [String: Any]) {
        let item = ImageComment(id: id, message: message, createdAt: createdAt.date, username: username)
        let json: [String: Any] = [
            "id": id.uuidString,
            "message": message,
            "created_at": createdAt.iso8601String,
            "author": [
                "username": username
            ]
        ]
        return (model: item, json: json)
    }

    func makeItemsJSON(_ items: [[String: Any]]) throws -> Data {
        try JSONSerialization.data(withJSONObject: ["items": items])
    }
}
