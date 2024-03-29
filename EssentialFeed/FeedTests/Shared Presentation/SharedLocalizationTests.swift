//
//  SharedLocalizationTests.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 22/11/23.
//

import Feed
import XCTest

final class SharedLocalizationTests: XCTestCase {
    func test_localizedStrings_haveKeysAndValuesForAllSupportedLocalizations() {
        let table = "Shared"
        let bundle = Bundle(for: LoadResourcePresenter<Any, DummyView>.self)
        assertLocalizedKeyAndValuesExist(in: bundle, table)
    }
}

private class DummyView: ResourceView {
    func display(_ viewModel: Any) {}
}
