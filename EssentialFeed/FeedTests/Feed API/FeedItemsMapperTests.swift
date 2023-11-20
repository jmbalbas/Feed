//
//  FeedItemsMapperTests.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 3/12/22.
//

import Feed
import Foundation
import XCTest

final class FeedItemsMapperTests: XCTestCase {
    func test_map_throwsErrorOnNon200HTTPResponse() throws {
        let json = try makeItemsJSON([])

        try [199, 201, 300, 400, 500].forEach { code in
            XCTAssertThrowsError(try FeedItemsMapper.map(json, from: HTTPURLResponse(statusCode: code)))
        }
    }

    func test_map_throwsErrorOn200HTTPResponseWithInvalidJSON() {
        let invalidJSON = Data("Invalid json".utf8)

        XCTAssertThrowsError(try FeedItemsMapper.map(invalidJSON, from: HTTPURLResponse(statusCode: 200)))
    }

    func test_map_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() throws {
        let emptyListJSON = try makeItemsJSON([])

        XCTAssertEqual(try FeedItemsMapper.map(emptyListJSON, from: HTTPURLResponse(statusCode: 200)), [])
    }

    func test_map_deliversItemsOn200HTTPResponseWithJSONItems() throws {
        let item1 = makeItem(id: UUID(), imageURL: URL(string: "http://a-url.com")!)
        let item2 = makeItem(id: UUID(), description: "A description", location: "A location", imageURL: URL(string: "http://another-url.com")!)
        let items = [item1, item2].map(\.model)
        let json = try makeItemsJSON([item1, item2].map(\.json))

        XCTAssertEqual(try FeedItemsMapper.map(json, from: HTTPURLResponse(statusCode: 200)), items)
    }

}

// MARK: - Helpers

private extension FeedItemsMapperTests {
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

private extension HTTPURLResponse {
    convenience init(statusCode: Int) {
        self.init(url: anyURL, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}
