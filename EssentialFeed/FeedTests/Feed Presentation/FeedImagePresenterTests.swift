//
//  FeedImagePresenterTests.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 29/10/23.
//

import Feed
import XCTest

final class FeedImagePresenterTests: XCTestCase {
    func test_map_createsViewModel() {
        let image = uniqueImage

        let viewModel = FeedImagePresenter.map(image)

        XCTAssertEqual(viewModel.description, image.description)
        XCTAssertEqual(viewModel.location, image.location)
    }
}
