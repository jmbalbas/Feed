//
//  ImageCommentsSnapshotTests.swift
//  FeediOSTests
//
//  Created by Juan Santiago Martín Balbás on 23/11/23.
//

@testable import Feed
import FeediOS
import XCTest

final class ImageCommentsSnapshotTests: XCTestCase {
    func test_listWithComments() {
        let sut = makeSUT()

        sut.display(comments)

        assert(snapshot: sut.snapshot(for: .iPhone8(style: .light)), named: "IMAGE_COMMENTS_light")
        assert (snapshot: sut.snapshot(for: .iPhone8(style: .dark)), named: "IMAGE_COMMENTS_dark")
    }
}

private extension ImageCommentsSnapshotTests {
    var comments: [CellController] {
        commentControllers.map(CellController.init)
    }

    var commentControllers: [ImageCommentCellController] {
        [
            ImageCommentCellController(
                model: ImageCommentViewModel(
                    message:  "The East Side Gallery is an open-air gallery in Berlin. It consists of a series of murals painted directly on a 1,316 m long remnant of the Berlin Wall, located near the centre of Berlin, on Mühlenstraße in Friedrichshain-Kreuzberg. The gallery has official status as a Denkmal, or heritage-protected landmark.",
                    date: "1000 years ago",
                    username: "A long long long username"
                )
            ),
            ImageCommentCellController(
                model: ImageCommentViewModel(
                    message:  "East Side Gallery\nMemorial in Berlin, Germany",
                    date: "10 days ago",
                    username: "A username"
                )
            ),
            ImageCommentCellController(
                model: ImageCommentViewModel(
                    message:  "Nice!",
                    date: "1 hour ago",
                    username: "a."
                )
            )
        ]
    }


    func makeSUT() -> ListViewController {
        let bundle = Bundle(for:  ListViewController.self)
        let storyboard = UIStoryboard(name: "ImageComments", bundle: bundle)
        let controller = storyboard.instantiateInitialViewController() as! ListViewController
        controller.loadViewIfNeeded()
        return controller
    }
}
