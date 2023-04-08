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