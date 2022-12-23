//
//  URLSessionHTTPClientTests.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 22/12/22.
//

import XCTest

class URLSessionHTTPClient {
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func get(from url: URL) async throws -> (Data, URLResponse) {
        try await session.data(from: url)
    }
}

final class URLSessionHTTPClientTests: XCTestCase {

    override class func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }

    override class func tearDown() {
        URLProtocolStub.stopInterceptingRequests()
        super.tearDown()
    }

    func test_getFromURL_failsOnRequestError() async throws {
        let url = URL(string: "http://any-url.com")!
        let sut = URLSessionHTTPClient()
        let expectedError = NSError(domain: "Any error", code: 1)
        URLProtocolStub.stub(url: url, error: expectedError)

        await XCTAssertThrowsError(try await sut.get(from: url)) {
            let error = $0 as NSError
            XCTAssertEqual(expectedError.domain, error.domain)
            XCTAssertEqual(expectedError.code, error.code)
        }
    }
}

// MARK: - Helpers

private class URLProtocolStub: URLProtocol {
    private static var stubs: [URL: Stub] = [:]

    private struct Stub {
        let error: Error?
    }

    static func stub(url: URL, error: Error? = nil) {
        stubs[url] = Stub(error: error)
    }

    static func startInterceptingRequests() {
        URLProtocol.registerClass(Self.self)
    }

    static func stopInterceptingRequests() {
        URLProtocol.unregisterClass(Self.self)
        stubs = [:]
    }

    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url else { return false }
        return stubs[url] != nil
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url, let stub = Self.stubs[url] else { return }

        if let error = stub.error {
            client?.urlProtocol(self, didFailWithError: error)
        }

        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
