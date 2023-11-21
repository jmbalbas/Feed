//
//  ImageCommentsMapperTests.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 16/11/23.
//

import Feed
import XCTest

final class ImageCommentsMapperTests: XCTestCase {
    func test_map_throwsErrorOnNon2xxHTTPResponse() throws {
        let json = try makeItemsJSON([])

        try [199, 159, 300, 400, 500].forEach { code in
            XCTAssertThrowsError(try ImageCommentsMapper.map(json, from: HTTPURLResponse(statusCode: code)))
        }
    }

    func test_map_throwsErrorOn2xxHTTPResponseWithInvalidJSON() throws {
        let invalidJSON = Data("Invalid json".utf8)

        try [200, 201, 250, 280, 299].forEach { code in
            XCTAssertThrowsError(try ImageCommentsMapper.map(invalidJSON, from: HTTPURLResponse(statusCode: code)))
        }
    }

    func test_map_deliversNoItemsOn2xxHTTPResponseWithEmptyJSONList() throws {
        let emptyListJSON = try makeItemsJSON([])

        try [200, 201, 250, 280, 299].forEach { code in
            XCTAssertEqual(try ImageCommentsMapper.map(emptyListJSON, from: HTTPURLResponse(statusCode: 200)), [])
        }
    }

    func test_map_deliversItemsOn2xxHTTPResponseWithJSONItems() throws {
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

        try [200, 201, 250, 280, 299].forEach { code in
            XCTAssertEqual(try ImageCommentsMapper.map(json, from: HTTPURLResponse(statusCode: 200)), items)
        }
    }

}

// MARK: - Helpers

private extension ImageCommentsMapperTests {
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
}
