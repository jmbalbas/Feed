//
//  ImageCommentsLocalizationTests.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 23/11/23.
//

import Feed
import XCTest

final class ImageCommentsLocalizationTests: XCTestCase {
    func test_localizedStrings_haveKeysAndValuesForAllSupportedLocalizations() {
        let table = "ImageComments"
        let bundle = Bundle(for: ImageCommentsPresenter.self)
        assertLocalizedKeyAndValuesExist(in: bundle, table)
    }
}
