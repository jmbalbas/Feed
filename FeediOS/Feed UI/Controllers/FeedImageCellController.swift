//
//  FeedImageCellController.swift
//  FeediOS
//
//  Created by Juan Santiago Martín Balbás on 14/10/23.
//

import Feed
import UIKit

final class FeedImageCellController {
    private var task: FeedImageDataLoaderTask?
    private let model: FeedImage
    private let imageLoader: FeedImageDataLoader

    init(model: FeedImage, imageLoader: FeedImageDataLoader) {
        self.model = model
        self.imageLoader = imageLoader
    }

    deinit {
        task?.cancel()
    }

    func view() -> UITableViewCell {
        let cell = FeedImageCell()
        cell.locationContainer.isHidden = model.location == nil
        cell.locationLabel.text = model.location
        cell.descriptionLabel.text = model.description
        cell.feedImageView.image = nil
        cell.feedImageRetryButton.isHidden = true
        cell.feedImageContainer.startShimmering()
        let loadImage = { [weak self, weak cell] in
            guard let self else { return }
            self.loadImageData { [weak cell] result in
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

    func preload() {
        loadImageData()
    }

    private func loadImageData(completion: ((FeedImageDataLoader.Result) -> Void)? = nil) {
        task = imageLoader.loadImageData(from: model.url) {
            completion?($0)
        }
    }
}
