//
//  XCTestCase+MemoryLeakTracking.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 23/12/22.
//

import Foundation
import XCTest

extension XCTestCase {
    func trackForMemoryLeaks(_ instance: AnyObject, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated", line: line)
        }
    }
}
