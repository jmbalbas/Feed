//
//  URLSessionHTTPClientTests.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 22/12/22.
//

import XCTest
import Feed

final class URLSessionHTTPClientTests: XCTestCase {

    override func tearDown() {
        URLProtocolStub.removeStub()
        super.tearDown()
    }

    func test_getFromURL_performsGETRequestWithURL() {
        let url = anyURL
        let sut = givenSUT()
        let exp = expectation(description: "wait for completion")

        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }

        sut.get(from: url) { _ in }

        wait(for: [exp], timeout: 1)
    }

    func test_cancelGetFromURLTask_cancelsURLRequest() {
        let exp = expectation(description: "Wait for request")
        URLProtocolStub.observeRequests { _ in exp.fulfill() }

        let receivedError = resultErrorFor(taskHandler: { $0.cancel() }) as NSError?

        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(receivedError?.code, URLError.cancelled.rawValue)
    }

    func test_getFromURL_failsOnRequestError() {
        let error = anyNSError

        let receivedError = resultErrorFor((data: nil, response: nil, error: error)) as NSError?

        XCTAssertEqual(receivedError?.domain, error.domain)
        XCTAssertEqual(receivedError?.code, error.code)
    }

    func test_getFromURL_failsOnNonHTTPUrlResponse() {
        let error = resultErrorFor((data: nil, response: anyURLResponse(), error: nil)) as? URLSessionHTTPClient.Error

        XCTAssertEqual(error, .nonHTTPUrlResponse)
    }

    func test_getFromURL_succeedsOnHTTPURLResponseWithData() {
        let data = anyData
        let response = anyHTTPURLResponse()

        let resultValues = resultValuesFor((data: data, response: response, error: nil))

        XCTAssertEqual(data, resultValues?.data)
        let receivedResponse = resultValues?.response
        XCTAssertEqual(response.url, receivedResponse?.url)
        XCTAssertEqual(response.statusCode, receivedResponse?.statusCode)
    }
}

// MARK: - Helpers

private extension URLSessionHTTPClientTests {
    func givenSUT(file: StaticString = #filePath, line: UInt = #line) -> HTTPClient {
        let configuration: URLSessionConfiguration = .ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)

        let sut = URLSessionHTTPClient(session: session)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    func anyURLResponse() -> URLResponse {
        URLResponse(url: anyURL, mimeType: nil, expectedContentLength: 1, textEncodingName: nil)
    }

    func anyHTTPURLResponse() -> HTTPURLResponse {
        HTTPURLResponse(url: anyURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
    }

    func resultValuesFor(
        _ values: (data: Data?, response: URLResponse?, error: Error?),
        file: StaticString = #file,
        line: UInt = #line
    ) -> (data: Data, response: HTTPURLResponse)? {
        let result = resultFor(values, file: file, line: line)
        switch result {
        case .success(let resultValues):
            return resultValues
        case .failure:
            XCTFail("Expected success, got \(result) instead", file: file, line: line)
            return nil
        }
    }

    private func resultErrorFor(
        _ values: (data: Data?, response: URLResponse?, error: Error?)? = nil,
        taskHandler: (HTTPClientTask) -> Void = { _ in },
        file: StaticString = #file,
        line: UInt = #line
    ) -> Error? {
        let result = resultFor(values, taskHandler: taskHandler, file: file, line: line)
        switch result {
        case .success:
            XCTFail("Expected error, got \(result) instead", file: file, line: line)
            return nil
        case .failure(let error):
            return error
        }
    }

    private func resultFor(
        _ values: (data: Data?, response: URLResponse?, error: Error?)?,
        taskHandler: (HTTPClientTask) -> Void = { _ in },
        file: StaticString = #file,
        line: UInt = #line
    ) -> HTTPClient.Result {
        values.map { URLProtocolStub.stub(data: $0, response: $1, error: $2) }
        let sut = givenSUT(file: file, line: line)
        let exp = expectation(description: "Wait for completion")

        var receivedResult: HTTPClient.Result!
        taskHandler(sut.get(from: anyURL) { result in
            receivedResult = result
            exp.fulfill()
        })

        wait(for: [exp], timeout: 1.0)
        return receivedResult
    }
}
