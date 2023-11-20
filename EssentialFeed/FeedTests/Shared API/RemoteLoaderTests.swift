//
//  RemoteLoaderTests.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 19/11/23.
//

import Feed
import XCTest

final class RemoteLoaderTests: XCTestCase {
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

        expect(sut, toCompleteWith: failure(.connectivity), when: {
            complete(withError: NSError(domain: "Test", code: 0), using: client)
        })
    }


    func test_load_deliversErrorOnMapperError() {
        let (sut, client) = givenSUT(mapper: { _, _ in
            throw anyNSError
        })

        expect(sut, toCompleteWith: failure(.invalidData), when: {
            complete(withStatusCode: 200, data: anyData, using: client)
        })
    }

    func test_load_deliversMappedResource() throws {
        let resource = "A resource"
        let (sut, client) = givenSUT(mapper: { data, _ in
            String(data: data, encoding: .utf8)!
        })

        expect(sut, toCompleteWith: .success(resource), when: {
            complete(withStatusCode: 200, data: Data(resource.utf8), using: client)
        })
    }
}

// MARK: - Helpers

private extension RemoteLoaderTests {
    func givenSUT(
        url: URL = URL(string: "https://a-url.com")!,
        mapper: @escaping RemoteLoader<String>.Mapper = { _, _ in "any" },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: RemoteLoader<String>, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteLoader<String>(client: client, url: url, mapper: mapper)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, client)
    }

    func whenCallingLoad(on sut: RemoteLoader<String>, completion: @escaping (RemoteLoader<String>.Result) -> Void = { _ in }) {
        sut.load(completion: completion)
    }

    func complete(withError error: Error, using client: HTTPClientSpy, at index: Int = 0) {
        client.complete(with: error, at: index)
    }

    func complete(withStatusCode code: Int = 200, data: Data = Data(), using client: HTTPClientSpy, at index: Int = 0) {
        client.complete(withStatusCode: code, data: data, at: index)
    }

    func failure(_ error: RemoteLoader<String>.Errors) -> RemoteLoader<String>.Result {
        .failure(error)
    }

    func expect(
        _ sut: RemoteLoader<String>,
        toCompleteWith expectedResult: RemoteLoader<String>.Result,
        when action: () -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for load completion")

        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedItems), .success(expectedItems)):
                XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)

            case let (.failure(receivedError as RemoteLoader<String>.Errors), .failure(expectedError as RemoteLoader<String>.Errors)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)

            default:
                XCTFail("Expected result \(expectedResult) got \(receivedResult) instead", file: file, line: line)
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
