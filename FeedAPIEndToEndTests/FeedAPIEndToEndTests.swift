//
//  FeedAPIEndToEndTests.swift
//  FeedAPIEndToEndTests
//
//  Created by Juan Santiago Martín Balbás on 30/12/22.
//

import XCTest
import Feed

final class FeedAPIEndToEndTests: XCTestCase {

    func test_endToEndTestServerGETFeedResult_matchesFixedTestAccountData() async throws  {
        let items = try await getFeedResult()

        XCTAssertEqual(items.count, 8)
        XCTAssertEqual(items[0], expectedItem(at: 0))
        XCTAssertEqual(items[1], expectedItem(at: 1))
        XCTAssertEqual(items[2], expectedItem(at: 2))
        XCTAssertEqual(items[3], expectedItem(at: 3))
        XCTAssertEqual(items[4], expectedItem(at: 4))
        XCTAssertEqual(items[5], expectedItem(at: 5))
        XCTAssertEqual(items[6], expectedItem(at: 6))
        XCTAssertEqual(items[7], expectedItem(at: 7))
    }

}

private extension FeedAPIEndToEndTests {

    func getFeedResult(file: StaticString = #filePath, line: UInt = #line) async throws -> [FeedItem] {
        let testServerURL = URL(string: "https://essentialdeveloper.com/feed-case-study/test-api/feed")!
        let client = URLSessionHTTPClient()
        let loader = RemoteFeedLoader(client: client, url: testServerURL)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(loader, file: file, line: line)

        let exp = expectation(description: "wait for load completion")

        let task = Task {
            let items = try await loader.load()
            exp.fulfill()
            return items
        }

        await waitForExpectations(timeout: 10)
        return try await task.value
    }

    func expectedItem(at index: Int) -> FeedItem {
        FeedItem(
            id: id(at: index),
            description: description(at: index),
            location: location(at: index),
            imageURL: imageURL(at: index)
        )
    }

    func id(at index: Int) -> UUID {
        UUID(uuidString: [
            "73A7F70C-75DA-4C2E-B5A3-EED40DC53AA6",
            "BA298A85-6275-48D3-8315-9C8F7C1CD109",
            "5A0D45B3-8E26-4385-8C5D-213E160A5E3C",
            "FF0ECFE2-2879-403F-8DBE-A83B4010B340",
            "DC97EF5E-2CC9-4905-A8AD-3C351C311001",
            "557D87F1-25D3-4D77-82E9-364B2ED9CB30",
            "A83284EF-C2DF-415D-AB73-2A9B8B04950B",
            "F79BD7F8-063F-46E2-8147-A67635C3BB01"
        ][index])!
    }

    func description(at index: Int) -> String? {
        [
            "Description 1",
            nil,
            "Description 3",
            nil,
            "Description 5",
            "Description 6",
            "Description 7",
            "Description 8"
        ][index]
    }

    func location(at index: Int) -> String? {
        [
            "Location 1",
            "Location 2",
            nil,
            nil,
            "Location 5",
            "Location 6",
            "Location 7",
            "Location 8"
        ][index]
    }

    func imageURL(at index: Int) -> URL {
        URL(string: "https://url-\(index + 1).com")!
    }
}
