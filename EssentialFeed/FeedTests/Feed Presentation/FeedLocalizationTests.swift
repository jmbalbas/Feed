//
//  FeedLocalizationTests.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 29/10/23.
//

import XCTest
import Feed

final class FeedLocalizationTests: XCTestCase {
    func test_localizedStrings_haveKeysAndValuesForAllSupportedLocalizations() {
        let table = "Feed"
        let bundle = Bundle(for: FeedPresenter.self)
        assertLocalizedKeyAndValuesExist(in: bundle, table)
    }
}
