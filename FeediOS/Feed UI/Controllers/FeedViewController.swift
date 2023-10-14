//
//  FeedViewController.swift
//  FeediOS
//
//  Created by Juan Santiago Martín Balbás on 7/10/23.
//

import Feed
import UIKit

public final class FeedViewController: UITableViewController {
    private var refreshController: FeedRefreshViewController?
    private var imageLoader: FeedImageDataLoader?
    private var tableModel: [FeedImage] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    private var tasks: [IndexPath: FeedImageDataLoaderTask] = [:]

    public convenience init(feedLoader: FeedLoader, imageLoader: FeedImageDataLoader?) {
        self.init()
        self.refreshController = FeedRefreshViewController(feedLoader: feedLoader)
        self.imageLoader = imageLoader
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        refreshControl = refreshController?.view
        refreshController?.onRefresh = { [weak self] feed in
            self?.tableModel = feed
        }

        tableView.prefetchDataSource = self

        refreshController?.refresh()
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableModel.count
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellModel = tableModel[indexPath.row]
        let cell = FeedImageCell()
        cell.locationContainer.isHidden = cellModel.location == nil
        cell.locationLabel.text = cellModel.location
        cell.descriptionLabel.text = cellModel.description
        cell.feedImageView.image = nil
        cell.feedImageRetryButton.isHidden = true
        cell.feedImageContainer.startShimmering()
        let loadImage = { [weak self, weak cell] in
            guard let self else { return }
            tasks[indexPath] = imageLoader?.loadImageData(from: cellModel.url) { [weak cell] result in
                cell?.feedImageContainer.stopShimmering()
                let data = try? result.get()
                let image = data.flatMap(UIImage.init)
                cell?.feedImageView.image = image
                cell?.feedImageRetryButton.isHidden = image != nil
            }
        }

        loadImage()
        cell.onRetry = loadImage
        return cell
    }

    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cancelTask(forRowAt: indexPath)
    }

    private func cancelTask(forRowAt indexPath: IndexPath) {
        tasks[indexPath]?.cancel()
        tasks[indexPath] = nil
    }
}

extension FeedViewController: UITableViewDataSourcePrefetching {
    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            let cellModel = tableModel[indexPath.row]
            tasks[indexPath] = imageLoader?.loadImageData(from: cellModel.url) { _ in }
        }
    }

    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach(cancelTask)
    }
}
