//
//  SharedTestHelpers.swift
//  EssentialAppTests
//
//  Created by Juan Santiago Martín Balbás on 5/11/23.
//

import Foundation

var anyURL: URL {
    URL(string: "http://a-url.com")!
}

var anyData: Data {
    Data("any data".utf8)
}

var anyNSError: NSError {
    NSError(domain: "any error", code: 0)
}
