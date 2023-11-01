//
//  RemoteFeedImageDataLoaderTests.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 1/11/23.
//

import Feed
import XCTest

class RemoteFeedImageDataLoader {
    init(client: Any) {

    }
}

class RemoteFeedImageDataLoaderTests: XCTestCase {

    func test_init_doesNotPerformAnyURLRequest() {
        let (_, client) = makeSUT()

        XCTAssert(client.requestedURLs.isEmpty)
    }

}

private extension RemoteFeedImageDataLoaderTests {
    func makeSUT(
        url: URL = anyURL,
        file: StaticString = #file,
        line: UInt = #line
    ) -> (sut: RemoteFeedImageDataLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedImageDataLoader(client: client)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(client, file: file, line: line)
        return (sut, client)
    }
}

private class HTTPClientSpy {
    var requestedURLs = [URL]()
}
