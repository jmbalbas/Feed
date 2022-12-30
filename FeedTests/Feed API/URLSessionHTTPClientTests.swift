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

    func test_getFromURL_failsOnRequestError() async {
        let error = NSError(domain: "Any error", code: 1)

        let receivedError = await resultErrorFor(error: error) as? NSError

        XCTAssertEqual(receivedError?.domain, error.domain)
        XCTAssertEqual(receivedError?.code, error.code)
    }

    func test_getFromURL_failsOnNonHTTPUrlResponse() async throws {
        let error = await resultErrorFor(response: anyURLResponse(), error: nil) as? URLSessionHTTPClient.Error

        XCTAssertEqual(error, .nonHTTPUrlResponse)
    }

    func test_getFromURL_succeedsOnHTTPURLResponseWithData() async {
        let data = anyData()
        let response = anyHTTPURLResponse()

        let resultValues = await resultValuesFor(data: data, response: response)

        XCTAssertEqual(data, resultValues?.data)
        let receivedResponse = resultValues?.response
        XCTAssertEqual(response.url, receivedResponse?.url)
        XCTAssertEqual(response.statusCode, receivedResponse?.statusCode)
    }
}

// MARK: - Helpers

private extension URLSessionHTTPClientTests {
    func givenSUT(file: StaticString = #filePath, line: UInt = #line) -> HTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    func anyURL() -> URL {
        URL(string: "http://any-url.com")!
    }

    func anyData() -> Data {
        Data("any data".utf8)
    }

    func anyURLResponse() -> URLResponse {
        URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 1, textEncodingName: nil)
    }

    func anyHTTPURLResponse() -> HTTPURLResponse {
        HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
    }

    func resultValuesFor(
        data: Data,
        response: URLResponse,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async -> (data: Data, response: HTTPURLResponse)? {
        let result = await resultFor(data: data, response: response, error: nil)
        switch result {
        case .success(let resultValues):
            return resultValues
        case .failure:
            XCTFail("Expected success, got \(result) instead", file: file, line: line)
            return nil
        }
    }

    func resultErrorFor(
        response: URLResponse? = nil,
        error: Error?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async -> Error? {
        let result = await resultFor(data: nil, response: response, error: error)
        switch result {
        case .success:
            XCTFail("Expected error, got \(result) instead", file: file, line: line)
            return nil
        case .failure(let error):
            return error
        }
    }

    func resultFor(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async -> Result<(data: Data, response: HTTPURLResponse), Error> {
        do {
            URLProtocolStub.stub(data: data, response: response, error: error)
            let sut = givenSUT(file: file, line: line)
            return .success(try await sut.get(from: anyURL()))
        } catch {
            return .failure(error)
        }
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
