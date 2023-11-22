//
//  FeedUIIntegrationTests+Localization.swift
//  FeediOSTests
//
//  Created by Juan Santiago Martín Balbás on 21/10/23.
//

import Feed
import Foundation
import XCTest

extension FeedUIIntegrationTests {
    private class DummyView: ResourceView {
        func display(_ viewModel: Any) {}
    }

    var loadError: String {
        LoadResourcePresenter<Any, DummyView>.loadError
    }

    var feedTitle: String {
        FeedPresenter.title
    }
}
