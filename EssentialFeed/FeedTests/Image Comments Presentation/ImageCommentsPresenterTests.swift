//
//  ImageCommentsPresenterTests.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 23/11/23.
//

import Feed
import XCTest

final class ImageCommentsPresenterTests: XCTestCase {
    func test_title_isLocalized() {
        XCTAssertEqual(ImageCommentsPresenter.title, localized("IMAGE_COMMENTS_VIEW_TITLE"))
    }

    func test_map_createsViewModels() {
        let now = Date()
        let comments = [
            ImageComment(
                id: UUID(),
                message: "A message",
                createdAt: now.adding(minutes: -5),
                username: "A username"
            ),
            ImageComment(
                id: UUID(),
                message: "Another message",
                createdAt: now.adding(days: -1),
                username: "Another username"
            )
        ]

        let viewModel = ImageCommentsPresenter.map(comments)

        XCTAssertEqual(
            viewModel.comments,
            [
                ImageCommentViewModel(
                    message: "A message",
                    date: "hace 5 minutos",
                    username: "A username"
                ),
                ImageCommentViewModel(
                    message: "Another message",
                    date: "hace 1 día",
                    username: "Another username"
                )
            ]
        )
    }
}

private extension ImageCommentsPresenterTests {
    func localized(_ key: String , file: StaticString = #file, line: UInt = #line) -> String {
        let table = "ImageComments"
        let bundle = Bundle(for: ImageCommentsPresenter.self)
        let value = bundle.localizedString(forKey: key, value: nil, table: table)
        if value == key {
            XCTFail("Missing localized string for key: \(key) in table: \(table)", file: file, line: line)
        }
        return value
    }
}
