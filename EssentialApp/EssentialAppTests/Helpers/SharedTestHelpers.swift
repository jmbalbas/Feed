//
//  SharedTestHelpers.swift
//  EssentialAppTests
//
//  Created by Juan Santiago Martín Balbás on 5/11/23.
//

import Feed
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

var uniqueFeed: [FeedImage] {
    [FeedImage(id: UUID(), description: "Description", location: "Location", url: URL(string: "https://any-url.com")!)]
}

private class DummyView: ResourceView {
    func display(_ viewModel: Any) {}
}

var loadError: String {
    LoadResourcePresenter<Any, DummyView>.loadError
}

var feedTitle: String {
    FeedPresenter.title
}

var commentsTitle: String {
    ImageCommentsPresenter.title
}
