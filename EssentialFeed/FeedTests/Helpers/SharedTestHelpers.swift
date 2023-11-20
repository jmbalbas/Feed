//
//  SharedTestHelpers.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 8/4/23.
//

import Foundation

var anyNSError: NSError {
    NSError(domain: "Any error", code: 1)
}

var anyURL: URL {
    URL(string: "http://any-url.com")!
}

var anyData: Data {
    Data("any data".utf8)
}

func makeItemsJSON(_ items: [[String: Any]]) throws -> Data {
    try JSONSerialization.data(withJSONObject: ["items": items])
}

extension HTTPURLResponse {
    convenience init(statusCode: Int) {
        self.init(url: anyURL, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}
