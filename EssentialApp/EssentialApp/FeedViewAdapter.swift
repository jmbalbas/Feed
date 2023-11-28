//
//  FeedViewAdapter.swift
//  FeediOS
//
//  Created by Juan Santiago Martín Balbás on 22/10/23.
//

import Combine
import Feed
import FeediOS
import UIKit

final class FeedViewAdapter: ResourceView {
    private weak var controller: ListViewController?
    private let imageLoader: (URL) -> FeedImageDataLoader.Publisher
    private let selection: (FeedImage) -> Void

    private typealias ImageDataPresentationAdapter = LoadResourcePresentationAdapter<Data, WeakRefVirtualProxy<FeedImageCellController>>

    init(
        controller: ListViewController,
        imageLoader: @escaping (URL) -> FeedImageDataLoader.Publisher,
        selection: @escaping (FeedImage) -> Void
    ) {
        self.controller = controller
        self.imageLoader = imageLoader
        self.selection = selection
    }

    func display(_ viewModel: Paginated<FeedImage>) {
        let feed: [CellController] = viewModel.items.map { model in
            let adapter = ImageDataPresentationAdapter(loader: { [imageLoader] in
                imageLoader(model.url)
            })

            let view = FeedImageCellController(
                viewModel: FeedImagePresenter.map(model),
                delegate: adapter,
                selection: { [selection] in
                    selection(model)
                })
            adapter.presenter = LoadResourcePresenter(
                resourceView: WeakRefVirtualProxy(view),
                loadingView: WeakRefVirtualProxy(view),
                errorView: WeakRefVirtualProxy(view),
                mapper: { data in
                    guard let image = UIImage(data: data) else {
                        throw InvalidImageDataError()
                    }
                    return image
                })
            return CellController(id: model, view)
        }
        let loadMore = LoadMoreCellController {
            viewModel.loadMore?({ _ in })
        }
        let loadMoreSection = [CellController(id: UUID(), loadMore)]

        controller?.display(feed, loadMoreSection)
    }
}

private struct InvalidImageDataError: Error {}
