//
//  FeedUIIntegrationTests+Assertions.swift
//  FeediOSTests
//
//  Created by Juan Santiago Martín Balbás on 14/10/23.
//

import Feed
import FeediOS
import XCTest

extension FeedUIIntegrationTests {
    func assertThat(
        _ sut: ListViewController,
        isRendering feed: [FeedImage],
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        guard sut.numberOfRenderedFeedImageViews == feed.count else {
            return XCTFail("Expected \(feed.count) images, got \(sut.numberOfRenderedFeedImageViews) instead.", file: file, line: line)
        }

        try feed.enumerated().forEach {
            try assertThat(sut, hasViewConfiguredFor: $0.element, at: $0.offset, file: file, line: line)
        }
    }

    func assertThat(
        _ sut: ListViewController,
        hasViewConfiguredFor image: FeedImage,
        at index: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let view = sut.feedImageView(at: index)

        let cell = try XCTUnwrap(
            view as? FeedImageCell,
            "Expected \(FeedImageCell.self) instance, got \(String(describing: view)) instead",
            file: file,
            line: line
        )

        let shouldLocationBeVisible = image.location != nil
        XCTAssertEqual(
            cell.isShowingLocation,
            shouldLocationBeVisible,
            "Expected `isShowingLocation` to be \(shouldLocationBeVisible) for image view at index \(index)",
            file: file,
            line: line
        )

        XCTAssertEqual(
            cell.locationText,
            image.location,
            "Expected location text to be \(String(describing: image.location)) for image view at index \(index)",
            file: file,
            line: line
        )

        XCTAssertEqual(
            cell.descriptionText,
            image.description,
            "Expected description text to be \(String(describing: image.description)) for image view at index \(index)",
            file: file,
            line: line
        )
    }
}
