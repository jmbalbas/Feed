//
//  URLSessionHTTPClientTests.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 22/12/22.
//

import XCTest
import Feed

class URLSessionHTTPClient: HTTPClient {
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(from: url)
        guard let httpURLResponse = response as? HTTPURLResponse else {
            throw Error.nonHTTPUrlResponse
        }
        return (data, httpURLResponse)
    }
}

extension URLSessionHTTPClient {
    enum Error: Swift.Error {
        case nonHTTPUrlResponse
    }
}

final class URLSessionHTTPClientTests: XCTestCase {

    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }

    override func tearDown() {
        URLProtocolStub.stopInterceptingRequests()
        super.tearDown()
    }

    func test_getFromURL_performsGETRequestWithURL() async {
        let url = anyURL()
        let sut = givenSUT()
        let exp = expectation(description: "wait for completion")

        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }

        _ = try? await sut.get(from: url)

        wait(for: [exp], timeout: 1)
    }

    func test_getFromURL_failsOnRequestError() async throws {
        let sut = givenSUT()
        let expectedError = NSError(domain: "Any error", code: 1)
        URLProtocolStub.stub(data: nil, response: nil, error: expectedError)

        await XCTAssertThrowsError(try await sut.get(from: anyURL())) {
            let error = $0 as NSError
            XCTAssertEqual(expectedError.domain, error.domain)
            XCTAssertEqual(expectedError.code, error.code)
        }
    }

    func test_getFromURL_failsOnNonHTTPUrlResponse() async throws {
        let sut = givenSUT()
        let data = Data()
        let url = anyURL()
        let response = URLResponse(url: url, mimeType: nil, expectedContentLength: 1, textEncodingName: nil)
        URLProtocolStub.stub(data: data, response: response, error: nil)

        await XCTAssertThrowsError(try await sut.get(from: url)) {
            XCTAssertEqual($0 as? URLSessionHTTPClient.Error, .nonHTTPUrlResponse)
        }
    }

    func test_getFromURL_succeedsOnHTTPURLResponseWithData() async throws {
        let sut = givenSUT()
        let data = Data()
        let url = anyURL()
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        URLProtocolStub.stub(data: data, response: response, error: nil)

        let (receivedData, receivedResponse) = try await sut.get(from: anyURL())
        
        XCTAssertEqual(data, receivedData)
        XCTAssertEqual(response.url, receivedResponse.url)
        XCTAssertEqual(response.statusCode, receivedResponse.statusCode)
    }
}

// MARK: - Helpers

private extension URLSessionHTTPClientTests {
    func givenSUT(file: StaticString = #filePath, line: UInt = #line) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    func anyURL() -> URL {
        URL(string: "http://any-url.com")!
    }
}

private class URLProtocolStub: URLProtocol {
    private static var stub: Stub?
    private static var requestObserver: ((URLRequest) -> Void)?

    private struct Stub {
        let data: Data?
        let response: URLResponse?
        let error: Error?
    }

    static func stub(data: Data?, response: URLResponse?, error: Error? = nil) {
        stub = Stub(data: data, response: response, error: error)
    }

    static func observeRequests(observer: @escaping (URLRequest) -> Void) {
        requestObserver = observer
    }

    static func startInterceptingRequests() {
        URLProtocol.registerClass(Self.self)
    }

    static func stopInterceptingRequests() {
        URLProtocol.unregisterClass(Self.self)
        stub = nil
        requestObserver = nil
    }

    override class func canInit(with request: URLRequest) -> Bool {
        requestObserver?(request)
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        if let data = Self.stub?.data {
            client?.urlProtocol(self, didLoad: data)
        }

        client?.urlProtocol(self, didReceive: Self.stub?.response ?? URLResponse(), cacheStoragePolicy: .notAllowed)

        if let error = Self.stub?.error {
            client?.urlProtocol(self, didFailWithError: error)
        }

        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
