//
//  XCTestCase+MemoryLeakTracking.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 23/12/22.
//

import Combine
import Foundation
import XCTest

extension XCTestCase {
    func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated", file: file, line: line)
        }
    }

    @MainActor
    func assert<E: Equatable>(
        publisher: Published<E>.Publisher,
        equals expectedValue: E,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        let expectation = expectation(description: "Changes to expected value")
        var cancellable: AnyCancellable?
        var currentValue: E?
        cancellable = publisher.receive(on: DispatchQueue.main).sink { newValue in
            currentValue = newValue
            if newValue == expectedValue {
                expectation.fulfill()
                cancellable?.cancel()
            }
        }

        await fulfillment(of: [expectation], timeout: 1)
        if currentValue != expectedValue {
            XCTFail("Expected \(expectedValue), got \(String(describing: currentValue))", file: file, line: line)
        }
    }
}
